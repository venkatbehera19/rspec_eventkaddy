class ExhibitorRegistrationsController < ApplicationController
  layout 'customized_registrations'
  skip_before_action :verify_authenticity_token
  before_action :set_ga_key, :get_settings

  include Registration

  def index
    @event                        = Event.find params[:event_id]
    @registration_portal_settings = @settings.json

    if !@settings.closing_date.blank?
        @closing_date_time        = (!@settings.closing_date.blank?) ?
        DateTime.strptime("#{@settings.closing_date} #{@settings.closing_date}","%m/%d/%Y %H:%M %p") :
        DateTime.strptime(@settings.closing_date,"%m/%d/%Y")

        @closing_date_time        = @closing_date_time.change(:offset => @event.utc_offset)
    end

    if @settings.landing.present?
      url = @event.cms_url + "/" + @event.id.to_s + @settings.landing
      redirect_to url
    end
  end

  def new
    @event_id       = params[:event_id].to_i
    @user           = User.new
  end

  def create
    user = User.where(email: user_params[:email]).first
    if user.present?
      exhibitor = Exhibitor.where( event_id: params[:event_id], user_id: user.id )
      if exhibitor.present?
        redirect_to '/', notice: "#{user.email} is a Exhibitor for this event. please login."
      else
        user_exhibitor_params = exhibitor_params.except(:password, :password_confirmation).to_json

        user.json = user_exhibitor_params
        user.first_name = exhibitor_params[:first_name]
        user.last_name  = exhibitor_params[:last_name]
        user.save

        event = Event.find params[:event_id]
        ExhibitorMailer.magical_link(user.email, event, user).deliver
        flash[:alert] = "A magical link has been sent to you. kindly check your email!."
        redirect_to "/#{params[:event_id]}/registrations/#{user.id}/instruction" and return
      end
    else
      new_user = User.new user_params
      if new_user.save
        user_event = new_user.users_events.where(event_id: params[:event_id]).first
        role_id = user_params[:role_ids][0]
        UserEventRole
          .find_or_create_by(role_id: role_id, users_event_id: user_event.id)
        exhibitor = Exhibitor.new(
          event_id: user_params[:event_ids],
          user_id: new_user.id,
          company_name: exhibitor_params[:company],
          city: exhibitor_params[:city],
          state: exhibitor_params[:state],
          country: exhibitor_params[:country],
          email: new_user.email,
          phone: exhibitor_params[:mobile_phone],
          url_twitter: exhibitor_params[:twitter_url],
          url_facebook: exhibitor_params[:facebook_url],
          url_linkedin: exhibitor_params[:linked_in]
        )
        exhibitor.save
        if @settings.have_payment_page
          session[:exhibitor_registration_id] = new_user.id
          redirect_to "/#{params[:event_id]}/exhibitor_registrations/payment/#{new_user.id}/select_booth"
        else
          redirect_to "/#{params[:event_id]}/exhibitor_registrations/registered/:id", notice: "#{new_user.email} registered as a Exhibitor"
        end
      end
    end
  end

  def confirmed
    event_id = params[:event_id]
    user_token  = params[:id]
    user = User.find_by(magic_link_token: user_token)

    if user.nil?
      flash[:alert] = "Something went wrong!, kindly contact admin."
      redirect_to "/#{params[:event_id]}/exhibitor_registrations" and return
    elsif user.magic_link_token_expires_at < Time.now
      flash[:alert] = "A magical link has been expired, kindly retry the registration."
      redirect_to "/#{params[:event_id]}/exhibitor_registrations" and return
    else
      cart = Cart.find_by(user: user)
      session[:exhibitor_registration_id] = user.id
      if cart.present?
        cart_items = cart.cart_items
        if cart_items.present?
          cart_items.delete_all
        end
      end
      session[:is_registered_user] = true
      redirect_to "/#{params[:event_id]}/exhibitor_registrations/payment/#{user.id}/select_booth" and return

    end
  end

  def registered
    @event    = Event.find params[:event_id]
  end

  def payment_success
    @event    = Event.find params[:event_id]
    cart = Cart.find_by(user_id: params[:user_id])
    cart.cart_items.destroy_all
    @order = Order.where(user_id: params[:user_id]).last
    if current_user && current_user.role?(:exhibitor)
      redirect_to '/exhibitor_portals/landing'
    end
  end

  def agenda
    @event    = Event.find params[:event_id]
  end

  def speakers
    @event    = Event.find params[:event_id]
  end

  def add_to_cart
    location_mapping = LocationMapping.where(id: params[:booth]).first

    if location_mapping.present?
			cart = Cart.find_by(user_id: params[:user_id])
			cart_item_in_cart = cart.cart_items.find_by(item_type: location_mapping.class.name)

			cart_item_in_cart.destroy if cart_item_in_cart # deleting same type of product already present in cart

			cart_item_added = CartItem.create(
        item_id: location_mapping.id,
        item_type: location_mapping.class.name,
        cart_id: cart.id
      )

			item_id    = location_mapping.id
			item_price = location_mapping.products.first&.price || 0

			item_added = {
				item_type:  'Booth',
				item_name:  location_mapping.name,
				item_price: item_price,
				item_id:    location_mapping.id
			}

			render json: {
									status:     true,
									message:    "Added To Cart",
									item_added: item_added,
                  cart_count: cart.total_cart_item_quantity
								}, status: :ok
			return
		end
    user    										= User.find params[:user_id] || current_user.id
		product 										= Product.find params[:product_id]
		type    										= params[:type]
		category_exclusions 				= CategoryExclusion.
																	where( excluded_category_id: product.product_category.id ).
    															pluck(:category_id)

		category_exclusions_reverse = CategoryExclusion.
																	where(category_id: product.product_category.id).
    															pluck(:excluded_category_id)

    if !product.is_product_available?
      render json: { message: "Product is Unavilable" }, status: :ok
      return
    end

    item_id    = product.id
		item_type  = 'Product'
		item_name  = product.name
		item_price = product.price
		item_added = {
			item_type:  item_type,
			item_name:  item_name,
			item_price: item_price,
			item_id:    item_id
		}

    cart             = Cart.find params[:cart_id]
		product_category = ProductCategory.find params[:category_id]

    if product_category.is_single_select_product?
      if !cart.check_category_item_is_present_in_cart? (product_category)
				if type == 'remove'
					cart_item = CartItem.find_by(
																item_id: product.id,
																item_type: product.class.name,
																cart_id: cart.id
															)
					cart_item.delete
					total_cart_item = cart.total_cart_item_quantity
					render json: {
									status: true,
									message: "Product Removed Successfully",
									type: type,
									data: cart_item,
									category_exclusions: category_exclusions,
									category_exclusions_reverse: category_exclusions_reverse,
									cart_count: total_cart_item
								}, status: :ok
					return
				elsif type == 'add'
					if product_category.iid == 'sponsorship_with_booth'
						cart = Cart.find params[:cart_id]
						cart_items = cart.cart_items.where(item_type: 'LocationMapping')
						if cart_items.present?
							cart_items.first.delete
						end
					end
					cart_item_added = CartItem.find_or_create_by(
																			item_id: product.id,
																			item_type: product.class.name,
																			cart_id: cart.id
																		)
          available_location_mapping = get_added_location_mapping_with_product_associated(product_category)
					available_location_mapping_data = available_location_mapping.map do |booth| {
            booth_id: booth.id,
            booth_name: booth.name,
            product_name: booth.products.first.name,
            product_price: booth.products.first.price
          } end
          total_cart_item = cart.total_cart_item_quantity
					render json: {
									status: true,
									message: "Product Added Successfully",
									type: type,
									data: cart_item_added,
									category_exclusions: category_exclusions,
									category_exclusions_reverse: category_exclusions_reverse,
									item_added: item_added,
									cart_count: total_cart_item,
									is_sponser_with_booth: product_category.iid == 'sponsorship_with_booth',
									is_sponser_with_booth_selection: product_category.iid == 'sponsorship_with_booth_selection',
									available_location_mapping: available_location_mapping_data
								}, status: :ok
					return
				end
			else
				if type == 'remove'
					cart_item       = remove_single_category_product(cart, product)
          available_location_mapping = get_deleted_location_mapping_with_product_associated(product_category)
					available_location_mapping_data = available_location_mapping.map do |booth| {
            booth_id: booth.id,
            booth_name: booth.name,
            product_name: booth.products.first.name,
            product_price: booth.products.first.price
          } end
          location_mapping_booth = cart.cart_items.where("item_type": "LocationMapping").first
          if location_mapping_booth.present?
            if location_mapping_booth.item.products.first.iid == 'premium_location'
              location_mapping_booth.delete
            end
          end
          total_cart_item = cart.total_cart_item_quantity
					render json: {
									status: true,
									message: "Product Removed Successfully",
									type: type,
									data: cart_item,
									category_exclusions: category_exclusions,
									category_exclusions_reverse: category_exclusions_reverse,
									item_added: item_added,
									cart_count: total_cart_item,
									is_sponser_with_booth_selection: product_category.iid == 'sponsorship_with_booth_selection',
									available_location_mapping: available_location_mapping_data
								}, status: :ok
					return
				else
					render json: {
									status: false,
									message: "Can't add this product to cart.",
								}, status: :ok
					return
				end
			end
    else
      if type == 'increase'
				cart_item_added = CartItem.find_by(
					item_id: product.id,
					item_type: product.class.name,
					cart_id: cart.id
				)
				if !cart_item_added.present?
					cart_item_added = CartItem.create(
						item_id: product.id,
						item_type: product.class.name,
						cart_id: cart.id
					)
				else
					quantity = cart_item_added.quantity
					cart_item_added.update_columns(quantity: quantity + 1)
				end
			else
				cart_item_added = CartItem.find_by(
					item_id: product.id,
					item_type: product.class.name,
					cart_id: cart.id
				)
				if cart_item_added.present?
					quantity = cart_item_added.quantity
					cart_item_added.update_columns(quantity: quantity - 1)
					if quantity-1 == 0
						cart_item_added.delete
					end
				else
					render json: { status: false, message: "Add the product to cart before removing it." }, status: :ok
					return
				end
			end
			total_cart_item = cart.total_cart_item_quantity
			render json: {
				status: true,
				message: "product updated sucessfully",
				data: cart_item_added ,
				category_exclusions: category_exclusions,
				category_exclusions_reverse: category_exclusions_reverse,
				type: type,
				item_added: item_added,
				cart_count: total_cart_item
				}, status: :ok
			return
    end
  end

  def cart
    cart_id  = params[:id]
    event_id = params[:event_id]
    @cart   = Cart.find cart_id

    @cart.status = 'on_cart_page'
    @cart.save

    cart_item = @cart.cart_items.find_by(item_type: 'LocationMapping')

    if !cart_item.nil?
      if !cart_item&.item&.is_available?
        cart_item.delete
        redirect_to "/#{event_id}/exhibitor_registrations/cart/#{@cart.id}", notice: "Booth is not available"
      end
    end

    if !@cart.cart_items.present?
      redirect_to "/#{event_id}/exhibitor_registrations/payment/#{@cart.user.id}/select_booth", notice: 'Cart is Empty.'
    end

    sponsorship_with_booth_selection_category = ProductCategory.find_by( iid: 'sponsorship_with_booth_selection', event_id: event_id )
    product_category_ids                      = @settings.product_categories_ids
    cart_items                                = @cart.cart_items.includes(:item).where(item_type: 'Product')
    category_ids                              = cart_items.map { |item| item.item.product_categories_id }.uniq

    if sponsorship_with_booth_selection_category && category_ids.include?(sponsorship_with_booth_selection_category.id)
      if cart_item.nil?
        redirect_to "/#{event_id}/exhibitor_registrations/payment/#{@cart.user.id}/select_booth", notice: 'Kindly Select the Booth first.'
      end
    end

    @total = @cart.calculate_total_amount_v2(sponsorship_with_booth_selection_category, category_ids)
  end

  def create_order_cart
    event_id   = params[:event_id]
    cart_id    = params[:id]
    cart       = Cart.find cart_id
    user       = cart.user
    cart_items = cart.cart_items

    if !cart_items.present?
      redirect_to "/#{event_id}/exhibitor_registrations/payment/#{user.id}/select_booth", notice: 'Cart is Empty.'
    end
    notice = ""
    is_product_not_avaialbale = false
    cart_items.each do |cart_item|
      if cart_item.item_type == 'LocationMapping'
        if !cart_item.item.is_available?
          redirect_to "/#{event_id}/exhibitor_registrations/payment/#{user.id}/select_booth", notice: 'Booth is not available.'
          break;
          return
        end
      else
        check_availability = cart_item.item.available_qantity > 0
        if !check_availability
          is_product_not_avaialbale = true
          notice = " product is unavailable. please remove #{cart_item.item.name} from cart"
          break;
        end
      end
    end

    created_order = user.create_order_for_exhibitor
    cart.status = 'on_payment_page'
    cart.save
    # binding.pry
    if is_product_not_avaialbale
      redirect_to "/#{event_id}/exhibitor_registrations/cart/#{cart.id}", alert: notice
    else
      redirect_to "/#{params[:event_id]}/exhibitor_registrations/payment/#{cart.id}/#{created_order.id}"
    end
  end

  private

  def get_settings
    @settings = Setting.return_exhibitor_registration_portal_settings(params[:event_id])
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name, :event_ids).
    merge({:role_ids => [].push(Role.find_by_name("Exhibitor").id)})
  end

  def exhibitor_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name, :mobile_phone, :company, :twitter_url, :facebook_url, :linked_in, :country, :state, :city, :event_ids)
  end

end
