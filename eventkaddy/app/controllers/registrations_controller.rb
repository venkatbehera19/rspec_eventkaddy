class RegistrationsController < ApplicationController
  layout 'customized_registrations'
  skip_before_action :verify_authenticity_token
  before_action :require_login, only: [:verify, :profile, :edit_profile, :update_profile]
  before_action :set_ga_key, :get_settings, except: [:create, :update_profile, :remove_bg_img, :create_section, :create_column, :remove_section, :remove_column, :stripe_create_payment,:stripe_complete_payment_registration_form, :stripe_create_payment_order, :apply_coupon, :remove_coupon,]

  include Registration
  # -------------------------------------- Registration Flow -----------------------------------------
  # Previous flow: Email verified -> Sign Up (with password only) -> Email verification -> Login to view and edit profile post email confirmation.
  # Regsitration has been customized to be like a Simple Sign up: Click Register -> Registration Form -> Post Registration Page.
  # Please Note: There is email verfication proocess has also been omitted from the present customized flow.
  # These methods are temporarily not in use: :already_registered :verify, :profile, :edit_profile, :update_profile

  def index
    @event                        = Event.find params[:event_id]
    if current_user.present?
      return redirect_to @event.cms_url, alert: "you are logged in!"
    end
    @registration_portal_settings = @settings.json

    if !@settings.closing_date.blank?
        @closing_date_time        = (!@settings.closing_date.blank?) ?
        DateTime.strptime("#{@settings.closing_date} #{@settings.closing_date}","%m/%d/%Y %H:%M %p") :
        DateTime.strptime(@settings.closing_date,"%m/%d/%Y")

        @closing_date_time        = @closing_date_time.change(:offset => @event.utc_offset)
    end

    configuration_file_path = File.expand_path('config/your_membership.yml')
    client_configuration    = YAML::load(File.open(configuration_file_path))
    environment             = "default"
    @app_id                 = client_configuration[environment]["app_id"]

    if @settings.landing.present?
      url = @event.cms_url + "/" + @event.id.to_s + @settings.landing
      redirect_to url
    end
  end

  def new
    @event_id       = params[:event_id].to_i
    @event          = Event.find_by(id: @event_id)
    @tab_type_ids  = TabType.where(portal:"attendee").pluck(:id)
    tabs          = Tab.where(
      event_id: params[:event_id],
      tab_type_id: @tab_type_ids
    ).order(:order)
    @current_tab = tabs.first
    if params[:is_member].present?
      @is_member = true
    end
    if params[:email]
      @attendee       = Attendee.new(
        event_id: @event_id,
        email:    params[:email],
        first_name: params[:first_name],
        last_name: params[:last_name],
        mobile_phone: params[:mobile_phone],
        country: params[:country],
        city: params[:city],
        is_member: params[:is_member].to_s.downcase == "true" ? true : false
      )
    else
      @attendee       = Attendee.new(event_id: @event_id)
    end

    #   # NOTE: User can have many events and for each event a different attendee account
    #   # If user account is already present for some other event_id
    #   # Associate with current event and with a new attendee
  end

  def create
    get_settings
    @attendee = Attendee.where(event_id: params[:event_id], email: params[:attendee][:email]).first

    if !@attendee.blank?
      flash[:alert] = "Email address already registered please login"
      redirect_to "/#{params[:event_id]}/registrations/login_to_profile" and return
    end
    if params[:attendee][:password].present? && params[:attendee][:password] != params[:attendee][:password_confirmation]
      flash[:alert] = "Password Didn't Match"
      redirect_to "/#{params[:event_id]}/registrations/new" and return
    end
    user = User.where(email: params[:attendee][:email]).first
    if !user.nil?
      # send the magical verification link
      event = Event.find params[:event_id]
      AttendeeMailer.magical_link(user.email, event, user).deliver
      flash[:alert] = "A magical link has been sent to you. kindly check your email!."
      redirect_to "/#{params[:event_id]}/registrations/#{user.id}/instruction" and return
    end

    if get_settings.have_payment_page
      register_form = RegistrationForm.new attendee_params
      register_form.event_id = params[:event_id]
      register_form.status = "pending"
      register_form.save
      redirect_to "/#{params[:event_id]}/registrations/#{register_form.id}/products"
    else
      @attendee = Attendee.new attendee_params
      @attendee.event_id = params[:event_id]
      if @attendee.save!
        @settings.send_calendar_invite && CalendarInviteMailer.invite(params[:event_id],@attendee, @settings.attach_calendar_invite).deliver_now
        # CalendarInviteMailer.invite(params[:event_id],@attendee).deliver_now
        redirect_to  "/#{params[:event_id]}/registrations/registered/#{@attendee.slug}"
      else
        render action: 'new'
      end
    end

    # @attendee = Attendee.new attendee_params
    # @attendee.event_id = params[:event_id]
    # if @attendee.save!
    #   if get_settings.have_payment_page
    #     redirect_to "/#{params[:event_id]}/registrations/payment/#{@attendee.slug}"
    #   else
    #     @settings.send_calendar_invite && CalendarInviteMailer.invite(params[:event_id],@attendee, @settings.attach_calendar_invite).deliver_now
    #     # CalendarInviteMailer.invite(params[:event_id],@attendee).deliver_now
    #     redirect_to  "/#{params[:event_id]}/registrations/registered/#{@attendee.slug}"
    #   end
    # else
    #   render action: 'new'
    # end

  end

  def member

    event_id       = params[:event_id].to_i
    code           = params[:code]
    event          = Event.find_by(id: event_id)
    # calling the membership
    ym             = YmMembership.new()
    member         = ym.call(code)

    if member[:status]
      get_settings
      @attendee = Attendee.where(event_id: event.id, email: member[:data][:email]).first
      if !@attendee.blank?
        user = User.find_by(email: member[:data][:email])
        if !user.confirmed_at?
          user.confirm
        end
        flash[:alert] = "Email address already registered please login"
        redirect_to "/#{event.id}/registrations/login_to_profile" and return
      end
      if member[:data][:email].blank?
        redirect_to "/#{event.id}/registrations", alert: "Email can not be empty in your membership." and return
      else
        user = User.find_by(email: member[:data][:email])
        if user.present?
          user.update_columns(:is_member => true)
          if !user.confirmed_at?
            user.confirm
          end
          AttendeeMailer.magical_link(user.email, event, user).deliver
          flash[:alert] = "A magical link has been sent to you. kindly check your email!."
          redirect_to "/#{params[:event_id]}/registrations/#{user.id}/instruction" and return
        else
          redirect_to "/#{event.id}/registrations/new?email=#{member[:data][:email]}&first_name=#{member[:data][:first_name]}&last_name=#{member[:data][:last_name]}&mobile_phone=#{member[:data][:mobile_phone]}&country=#{member[:data][:country]}&city=#{member[:data][:city]}&is_member=true" and return
        end
      end
    else
      redirect_to "/#{event.id}/registrations", alert: member[:message]
    end

  end

  def register_with_ym
    session = nil
    cookies.clear
    reset_session
    event_id                = params[:event_id]
    configuration_file_path = File.expand_path('config/your_membership.yml')
    client_configuration    = YAML::load(File.open(configuration_file_path))
    environment             = "default"
    app_id                  = client_configuration[environment]["app_id"]
    redirect_to "https://www.compostingcouncil.org/lock.aspx?app_id=#{app_id}&redirect_uri=https://dev-athena-cms.eventkaddy.net/319/registrations/member&scope=full_profile"
  end

  def instruction
    user_id = params[:user_id]
    @user = User.find user_id
  end

  def confirmed
    event_id = params[:event_id]
    user_token  = params[:id]
    user = User.find_by(magic_link_token: user_token)

    if user.nil?
      flash[:alert] = "Something went wrong!, kindly contact admin."
      redirect_to "/#{params[:event_id]}/registrations/login_to_profile" and return
    elsif user.magic_link_token_expires_at < Time.now
      flash[:alert] = "A magical link has been expired, kindly retry the registration."
      redirect_to "/#{params[:event_id]}/registrations/login_to_profile" and return
    else
      cart = Cart.find_by(user: user)
      if cart.present?
        cart_items = cart.cart_items
        if cart_items.present?
          cart_items.delete_all
        end
      end
      session[:is_registered_user] = true
      redirect_to "/#{params[:event_id]}/registrations/#{user.id}/products" and return
    end
  end

  def products
    is_registered_user = session[:is_registered_user]
    if is_registered_user
      @user = User.find params[:id]
      @cart = Cart.find_or_create_by(user: @user)
      @cart_items = @cart.cart_items
    else
      @user = RegistrationForm.find_by(id: params[:id])
      @cart = RegistrationFormCart.find_or_create_by(registration_form: @user)
      @cart_items = @cart.registration_form_cart_items
    end
    @cart.update(status: 'on_product_select_page')
    product_category_ids = @settings.product_categories_ids
    @product_category = ProductCategory.where(id: product_category_ids);
    @product_category_with_product = ProductCategory.joins(:products).where(id: product_category_ids).order(:order).uniq
    @tab_type_ids  = TabType.where(portal:"attendee").pluck(:id)
    tabs          = Tab.where(
      event_id: params[:event_id],
      tab_type_id: @tab_type_ids
    ).order(:order)
    @current_tab = tabs.second
  end

  def delete_item
    cart_id                 = params[:cart_id]
    product_id              = params[:product_id]
    is_registered_user      = session[:is_registered_user]
    if is_registered_user
      @cart                   = Cart.find(cart_id)
      @user                   = @cart.user
      @item                   = @cart.cart_items.find_by(item_id: product_id);
    else
      @cart                   = RegistrationFormCart.find(cart_id)
      @user                   = @cart.registration_form
      @item                   = @cart.registration_form_cart_items.find_by(item_id: product_id);
    end
    @item.delete

    if @user.is_member
      @total = @cart.registration_form_cart_items.reduce(0) do |sum, item|
        if item.item_type == 'Product'
          sum = sum + (item.item.member_price * item.quantity )
        else
          sum = sum + (item.item.products.first.member_price * item.quantity)
        end
        sum
      end
    else
      @total = @cart.registration_form_cart_items.reduce(0) do |sum, item|
        if item.item_type == 'Product'
          sum = sum + (item.item.price * item.quantity )
        else
          sum = sum + (item.item.products.first.price * item.quantity)
        end
        sum
      end
    end
    if is_registered_user
      @updated_cart_items_length = Cart.find(cart_id).cart_items.length
    else
      @updated_cart_items_length = RegistrationFormCart.find(cart_id).registration_form_cart_items.length
    end
    if @updated_cart_items_length == 0
      respond_to do |format|
        format.js
      end
    else
      respond_to do |format|
        format.js
      end
    end
  end

  def update_cart
    is_registered_user      = session[:is_registered_user]
    @is_payment_page        = params[:is_payment_page]
    cart_id                 = params[:id]
    product_id              = params[:product_id]
    product_quantity        = params[:quantity]
    user_id                 = params[:user_id]
    size                    = params[:size]
    product                 = Product.find(product_id)
    if is_registered_user
      @user                   = User.find user_id
      @cart                   = Cart.find cart_id
      cart_item               = @cart.cart_items.where(item_id: product_id).first
    else
      if current_user.present?
        @user                   = User.find user_id
        @cart                   = Cart.find cart_id
        cart_item               = @cart.cart_items.where(item_id: product_id).first
      else
        @user                   = RegistrationForm.find(user_id)
        @cart                   = RegistrationFormCart.find(cart_id)
        cart_item               = @cart.registration_form_cart_items.where(item_id: product_id).first
      end
    end
    product_category        = product.product_category
    is_multi_select_product = product_category.multi_select_product
    is_single_product       = product_category.single_product
    product_cart_items      = @cart.registration_form_cart_items
    product_category_ids    = @settings.product_categories_ids
    if @user.is_member
      @total = total_amount_member @cart
    else
      @total = total_amount_non_member @cart
    end

    @product_category_with_product = ProductCategory.joins(:products)
                                                    .where(id: product_category_ids)
                                                    .order(:order).uniq
    if cart_item.present?

      if is_multi_select_product
        cart_item.update_attribute(:quantity, product_quantity)
        @cart.reload
        if cart_item.quantity == 0
          cart_item.delete
        end
      elsif is_single_product
        if cart_item.quantity == 1 && params[:type] == "remove"
          cart_item.delete
          @cart.reload
        end
      else
        cart_item.update_attribute(:quantity, product_quantity)
        @cart.reload
        if cart_item.quantity == 0
          cart_item.delete
        end
      end
      @cart.reload
      if @user.is_member
        @total = total_amount_member @cart
      else
        @total = total_amount_non_member @cart
      end
      if @is_payment_page
        respond_to do |format|
          format.js
        end
      else
        respond_to do |format|
          format.js
        end
      end

    else
      if is_single_product
        product_cart_items.each do |cart_item|
          product_item = cart_item.item
          if product_item.product_category.id == product_category.id
            if product_item.id != product_id.to_i
              cart_item.delete
            end
          end
        end
        # add the product to the cart
        if size.present?
          @cart.registration_form_cart_items.create(
            item_id: product_id,
            item_type: 'Product',
            size: size
          )
        else
          @cart.registration_form_cart_items.create(
            item_id: product_id,
            item_type: 'Product'
          )
        end
        @cart.reload
        respond_to do |format|
          format.js
        end

      else
        if size.present?
          @cart.registration_form_cart_items.create(
            item_id: product_id,
            item_type: 'Product',
            size: size
          )
        else
          @cart.registration_form_cart_items.create(
            item_id: product_id,
            item_type: 'Product'
          )
        end
        @cart.reload
        respond_to do |format|
          format.js
        end
      end
    end
  end

  def cart
    get_settings
    @is_registered_user      = session[:is_registered_user]
    cart_id = params[:id]
    if @is_registered_user
      @cart = Cart.find cart_id
      @user = @cart.user
    else
      @cart = RegistrationFormCart.find(cart_id)
      @user = @cart.registration_form
    end
    @cart.status = 'on_cart_page'
    @cart.save
    @tab_type_ids  = TabType.where(portal:"attendee").pluck(:id)
    tabs          = Tab.where(
      event_id: params[:event_id],
      tab_type_id: @tab_type_ids
    ).order(:order)
    @current_tab = tabs.third
    if @user.is_member
      @total = @cart.registration_form_cart_items.reduce(0) do |sum, item|
        if item.item_type == 'Product'
          sum = sum + (item.item.member_price * item.quantity )
        else
          sum = sum + (item.item.products.first.member_price * item.quantity)
        end
        sum
      end
    else
      @total = @cart.registration_form_cart_items.reduce(0) do |sum, item|
        if item.item_type == 'Product'
          sum = sum + (item.item.price * item.quantity )
        else
          sum = sum + (item.item.products.first.price * item.quantity)
        end
        sum
      end
    end
  end

  def select_tag
    @event    = Event.find params[:event_id]
    @tag_type = TagType.where(name: 'attendee').first
    @keywords = @event.tag_sets_hash ?
                @event.tag_sets_hash[@tag_type.id.to_s] ?
                @event.tag_sets_hash[@tag_type.id.to_s]&.flatten : [] : []
    @attendee = Attendee.find params[:attendee_id]
    @custom_form_type = CustomFormType.where( iid: 'attendee_registration').first
    @custom_form = CustomForm.where(
      event_id: @event.id,
      custom_form_type_id: @custom_form_type.id
    ).first
  end

  def update_attendee_form
    attendee_tags = params[:attendee][:tags_attendees]
    event_id      = params[:attendee][:event_id]
    tag_type      = params[:tag_type]
    attendee_id   = params[:attendee_id]
    custom_form_id = params[:custom_form_id]
    custom_form = CustomForm.find custom_form_id
    attendee    = Attendee.find attendee_id
    # creating attendee tags for attendee
    attendee_tags.each do |attendee_tag|
      if attendee_tag.present?
        tag = Tag.find_or_create_by(
          event_id: event_id,
          level: 1,
          leaf: true,
          parent_id: 0,
          name: attendee_tag,
          tag_type_id: tag_type)
        tag.tags_attendee.create(attendee_id: attendee_id)
      end
    end

    fields = custom_form.json
    if params[:user]
      fields.each do |field|
        field["value"] = params[:user][field["name"]]

        if field['type'] == "radio-group"
          field['values'].each do |radio_field|
            if radio_field["value"] == params[:user][field["name"]]
              radio_field["selected"] = true
            else
              radio_field["selected"] = false
            end
          end
        end

        if field['type'] == "checkbox-group"
          if params[:user][field['name']]
            field['values'].each do |check_field|
              if params[:user][field['name']].include?(check_field["value"])
                check_field["selected"] = true
              else
                check_field["selected"] = false
              end
            end
          end
        end
      end
    end

    if fields
      attendee.update_column(:custom_fields, JSON.generate(fields))
    else
      attendee.update_column(:custom_fields, JSON.generate([]))
    end

    current_user = attendee.user
    sign_in(current_user)
    session[:event_id] = event_id
    if current_user && current_user.role?(:attendee)
      redirect_to "/attendee_portals/landing/#{attendee.slug}"
    end

  end

  def create_order_cart
    cart_id = params[:id]
    is_registered_user      = session[:is_registered_user]
    if is_registered_user
      cart = Cart.find cart_id
      user = cart.user
      cart_items = cart.cart_items
    else
      cart = RegistrationFormCart.find(cart_id)
      user = cart.registration_form
      cart_items = cart.registration_form_cart_items
    end
    is_product_not_avaialbale = false;
    notice = ""
    cart_items.each do |cart_item|
      order_items_quantity = OrderItem.joins(:order).where(item_id: cart_item.item).where(orders: {status: ['paid', 'pending']}).length
      available_product_quantity = cart_item.item.quantity
      available_quantity = available_product_quantity - order_items_quantity
      if available_quantity <= 0
        is_product_not_avaialbale = true;
        notice = " product is unavailable. please remove #{cart_item.item.name} from cart"
        break;
      else
        puts "avilable products #{available_quantity}"
      end
    end
    # OrderItem.joins(:order).where(item_id: cart.registration_form_cart_items.first.item).where(orders: {status: ['paid', 'pending']}).length
    if is_registered_user
      created_order = user.create_order_for_attendee
    else
      created_order = user.create_order
    end

    DeleteOrderForAttendeeWorker.perform_in(600, created_order.id)
    cart.status = 'on_payment_page'
    cart.save
    if is_product_not_avaialbale
      redirect_to "/#{params[:event_id]}/registrations/attendee/cart/#{cart.id}", alert: notice
    else
      redirect_to "/#{params[:event_id]}/registrations/attendee/payment/#{cart.id}/#{created_order.id}"
    end
  end

  def attendee_payment
    get_settings
    cart_id   = params[:id]
    order_id  = params[:order_id]
    @event_id = params[:event_id]
    @is_registered_user      = session[:is_registered_user]
    if @is_registered_user
      @cart = Cart.find cart_id
      @user = @cart.user
    else
      @cart = RegistrationFormCart.find(cart_id)
      @user = @cart.registration_form
    end
    @order = Order.find(order_id);
    coupon_item = @order.order_items.where.not(coupon_id: nil)
    if coupon_item.present?
      @coupon = coupon_item.first.coupon
    end
    @registration_url = "/#{@event_id}/registrations/login_to_profile"
    @tab_type_ids  = TabType.where(portal:"attendee").pluck(:id)
    tabs          = Tab.where(
      event_id: params[:event_id],
      tab_type_id: @tab_type_ids
    ).order(:order)
    @current_tab = tabs.fourth

    mode_of_payment_id = Transaction.payment_available?(get_settings)
    if mode_of_payment_id.present?
      @mode_of_payment = ModeOfPayment.find_by(id: mode_of_payment_id)
    end

    if @mode_of_payment.name == 'Stripe'
      @stripe_env = @mode_of_payment.client_key

    elsif @mode_of_payment.name == 'PayPal'
      @client_id = @mode_of_payment.client_key
    end

    if @user.is_member
      @total = @order.order_items.reduce(0) do |sum, item|
        if item.item_type == 'Product'
          sum = sum + (item.item.member_price * item.quantity )
        else
          sum = sum + (item.item.products.first.member_price * item.quantity)
        end
        sum
      end
    else
      @total = @order.order_items.reduce(0) do |sum, item|
        if item.item_type == 'Product'
          sum = sum + (item.item.price * item.quantity )
        else
          sum = sum + (item.item.products.first.price * item.quantity)
        end
        sum
      end
    end
  end

  def set_up_transaction
    mode_of_payment_id = Transaction.payment_available?(get_settings)

    if mode_of_payment_id.present?
      mode_of_payment = ModeOfPayment.find_by(id: mode_of_payment_id)
    end

    if mode_of_payment.name == 'Stripe'
      @stripe_env = mode_of_payment.client_key

    elsif mode_of_payment.name == 'PayPal'
      @client_id = mode_of_payment.client_key
    end
    @transaction = Transaction.find_by(
      registration_form_carts_id: @cart.id,
      transaction_status_type: TransactionStatusType.pending
    )
    @transaction && (@transaction.mode_of_payment != mode_of_payment) && @transaction.update(
      mode_of_payment: mode_of_payment
    )
		@transaction = Transaction.create(
      mode_of_payment: mode_of_payment,
      transaction_status_type: TransactionStatusType.pending,
      registration_form_carts_id: @cart.id
      ) if @transaction.nil?
    @total = @cart.registration_form_cart_items.reduce(0) do |sum, item|
              if item.item_type == 'Product'
								sum = sum + (item.item.price * item.quantity )
							else
								sum = sum + (item.item.products.first.price * item.quantity)
							end
							sum
						end
  end

  def stripe_create_payment
    mode_of_payment_id = params[:transaction][:id]
    order_id           = params[:transaction][:order_id]
    mode_of_payment = ModeOfPayment.find_by(id: mode_of_payment_id)
    order           = Order.find_by(id: order_id)

    begin
      if order
        client_secret = PaymentGateways::StripeClient.create_payment_order_form(mode_of_payment, order)
        render json: client_secret
      end
    rescue StandardError => e
      render json: {error: e.message}, status: :unprocessable_entity
    end
  end

  def remove_coupon
    coupon = Coupon.find_by(coupon_code: params[:coupon_code])

    if coupon.nil?
      render json: { status: false, message: "Invalid Coupon" }, status: :ok
      return
    end
    order  = Order.find_by(id: params[:order_id])

    if order.nil?
      render json: { status: false, message: "Something went wrong" }, status: :ok
      return
    end
    order_items = order.order_items.where(coupon_id: coupon.id)

    # need to check the logic again
    if !order_items.present?
      render json: { status: false, message: "Coupon can not added yet" }, status: :ok
      return
    end

    @order_item = order_items.first
    if coupon.is_percentage?
      discounted_amount = @order_item.coupon_amount
      @item_price       = @order_item.price + discounted_amount
      @total            = order.total + discounted_amount
    else
      @item_price        = @order_item.price + @order_item.coupon_amount
      @total             = order.total + @order_item.coupon_amount
    end
    @order_item.update_columns(coupon_id: nil, price: @item_price, coupon_amount: 0)
    order.update_column(:total , @total)

    render json: {
      status: true,
      message: "#{coupon.coupon_code} Coupon remove successful",
      data: {
        item_id:    @order_item.id,
        item_price: @item_price,
        total:      @total
      }
    }, status: :ok
    return

  end

  def apply_coupon
    coupon = Coupon.find_by(coupon_code: params[:coupon_code])

    if coupon.nil?
      render json: { status: false, message: "Invalid Coupon" }, status: :ok
      return
    end
    order  = Order.find_by(id: params[:order_id])

    if order.nil?
      render json: { status: false, message: "Something went wrong" }, status: :ok
      return
    end
    order_items = order.order_items.where(item_id: coupon.product_id)

    if !order_items.present?
      render json: { status: false, message: "Coupon can not be apply to this products" }, status: :ok
      return
    end

    if coupon.is_useable?
      @order_item = order_items.first

      if @order_item.check_coupon_already_applied(coupon)
        render json: { status: false, message: "Same coupon can't be apply multiple times" }, status: :ok
        return
      end

      if @order_item.already_apply_by_user_or_registration_form(coupon)
        render json: { status: false, message: "Coupon can be applied once per user" }, status: :ok
        return
      end

      if coupon.check_expiration?
        render json: { status: false, message: "Coupon Expired" }, status: :ok
        return
      end

      if coupon.is_percentage?
        discounted_amount = (@order_item.price * coupon.amount / 100).round()
        @item_price        = @order_item.price - discounted_amount
        @total             = order.total - discounted_amount
        @order_item.update_columns(coupon_id: coupon.id, price: @item_price, coupon_amount: discounted_amount)
      else
        @item_price        = (@order_item.price - coupon.amount).round()
        @total             = order.total - coupon.amount
        @order_item.update_columns(coupon_id: coupon.id, price: @item_price, coupon_amount: coupon.amount)
      end
      order.update_column(:total , @total)
    end

    render json: {
      status: true,
      message: "#{coupon.coupon_code} Coupon apply successful",
      data: {
        item_id:    @order_item.id,
        item_price: @item_price,
        total:      @total
      }
    }, status: :ok
    return

  end

  def affinipay_create_payment
    is_registered_user = session[:is_registered_user]
    mode_of_payment_id = params[:mode_of_payment_id]
    order_id           = params[:order_id]
    payment_id         = params[:payment_id]
    event_id           = params[:event_id]
    mode_of_payment    = ModeOfPayment.find_by(id: mode_of_payment_id)
    order              = Order.find_by(id: order_id)
    begin
      if order.present?
        response = PaymentGateways::AffinipayRestApi.create_payment_attendee(mode_of_payment, payment_id, order)
        response_data = JSON.parse response.body

        if response.code == '200'
          order_transaction = OrderTransaction.where(transaction_id: response_data["id"]).first

          if order_transaction.present?
            order_transaction.update_column(:transaction_status, response_data["status"])
          end
          order.update_column(:status, 'paid')
          coupon_item = order.order_items.where.not(coupon_id: nil)

          if current_user.present?
            if !current_user.confirmed_at?
              current_user.confirm
              current_user.save
            end

            if coupon_item.present?
              coupon = Coupon.find coupon_item.first.coupon_id
              coupon_code_usage = CouponCodeUsage.create(
                coupon_id: coupon.id,
                user_id: current_user.id
              )
              coupon.decrement_remaining_usage
            end

            attendee = Attendee.find_by_slug session[:slug]
            if !attendee.present?
              render json: {
                status: false,
                message: 'Attendee can not found!. some thing went wrong'
              }
              return
            end

            # updating attendee registration_status to true if he purchased according to category
            if check_attendee_registration_product(@settings, order)
              if attendee.registration_status?
                attendee.update_attribute(:registration_status, true)
              end
            end

            amount = response_data["amount"]/100
            transaction = Transaction.create(
              amount: amount,
              external_status: response_data["status"],
              transaction_status_type: TransactionStatusType.success,
              attendee_id: attendee.id,
              mode_of_payment_id: mode_of_payment_id,
              external_payment_id: response_data["id"]
            )

            order.update_columns(transaction_id: transaction.id, user_id: current_user.id)
            AttendeeMailer.registration_attendee_receipt(params[:event_id], attendee, order).deliver

            render json: {
              user_id: current_user.id,
              status: true,
              order_id: order.id,
              transaction_id: transaction.id,
              time: transaction.created_at,
              amount: amount,
              email: current_user.email,
              message: 'payment sucessfull'
            }
            return

          end
          if is_registered_user
            @user = order.user

            if !@user.confirmed_at?
              @user.confirm
            end

            password = SecureRandom.base64(4)
            standard_attendee = AttendeeType.where(name: 'Standard Attendee').first
            @new_attendee = Attendee.new(
              email: order.user.email,
              user_id: order.user.id,
              is_member: order.user.is_member,
              event_id: event_id,
              password: password,
              first_name: @user.first_name,
              last_name: @user.last_name,
              attendee_type_id: standard_attendee.id,
              custom_filter_1: 'ATTENDEE',
              badge_name: @user.first_name
            )
            if check_attendee_registration_product(@settings, order)
              @new_attendee.registration_status = true
            end
            @new_attendee.save!
            # generating the QR codes
            @new_attendee.qr_image

            roles        = @user.roles.pluck(:name)
            users_events = @user.users_events

            if roles.length == 1 && users_events.count == 1
              if users_events.first.user_event_roles.count == 0
                UserEventRole.find_or_create_by(
                  role_id: @user.roles.first.id,
                  users_event_id: users_events.first.id
                )
              end
            end
            if !roles.include?('Speaker')
              # updating the password
              @user.password = password
              @user.password_confirmation = password
              @user.save

              user_data = {
                :user => {
                  :password =>  password
                }
              }

              AttendeeMailer.registration_attendee_email_password(params[:event_id], @new_attendee, user_data).deliver

            end
          else
            users = User.where(email: order.registration_form.email)
            if users.present?
              @user = users.first

              if !@user.confirmed_at?
                @user.confirm
              end
            else
              password = SecureRandom.base64(4)

              user_data = {
                :user => {
                  :password =>  password
                }
              }

              # credential mail
              @user = User.new(
                email: order.registration_form.email,
                password: password,
                password_confirmation: password,
                first_name: order.registration_form.first_name,
                last_name: order.registration_form.last_name
              )

              @user.save!
              if !@user.confirmed_at?
                @user.confirm
              end

              # create attendee
              @new_attendee = Attendee.new(order.registration_form.as_json(except: [:id, :status]))
              standard_attendee = AttendeeType.where(name: 'Standard Attendee').first
              @new_attendee.attendee_type_id = standard_attendee.id
              AttendeeMailer.registration_attendee_email_password(params[:event_id], @new_attendee, user_data).deliver
              # assign user
              @new_attendee.user_id = @user.id
              @new_attendee.password = password
              @new_attendee.custom_filter_1 = 'ATTENDEE'
              @new_attendee.badge_name = @user.first_name
              if check_attendee_registration_product(@settings, order)
                @new_attendee.registration_status = true
              end
              @new_attendee.save!
              @new_attendee.qr_image

            end
          end

          # coupon update and save the coupon usage details
          if coupon_item.present?
            coupon = Coupon.find coupon_item.first.coupon_id
            coupon_code_usage = CouponCodeUsage.new(coupon_id: coupon.id)
            if order.registration_form_id?
              coupon_code_usage.registration_form_id = order.registration_form_id
            end
            coupon_code_usage.user_id = @user.id
            coupon_code_usage.save
            coupon.decrement_remaining_usage
          end

          attendee_role = Role.find_by(name: 'Attendee')
          # assigning event to the users
          users_event = UsersEvent.find_or_create_by(
            user_id: @user.id,
            event_id: event_id
          )
          # assigning event roles to the user
          UserEventRole.find_or_create_by(
            role_id: attendee_role.id,
            users_event_id: users_event.id
          )
          # assiging roles to the user
          UsersRole.find_or_create_by(
            user_id: @user.id,
            role_id: attendee_role.id
          )
          # response.body
          response_data = JSON.parse response.body
          # assign attendee to tarnsaction
          #external_payment_id => affinipay payment ID (charge_id)
          amount = response_data["amount"]/100
          Rails.logger.info "#{amount}"
          transaction = Transaction.create(
              amount: amount,
              external_status: response_data["status"],
              transaction_status_type: TransactionStatusType.success,
              attendee_id: @new_attendee.id,
              mode_of_payment_id: mode_of_payment_id,
              external_payment_id: response_data["id"]
            )

          order.update_columns(transaction_id: transaction.id, user_id: @user.id)

          if !is_registered_user
            order.registration_form.update_attribute(:status, "success")
          end
          render json: {
            user_id: @user.id,
            status: true,
            order_id: order.id,
            transaction_id: transaction.id,
            time: transaction.created_at,
            amount: amount,
            email: @user.email,
            message: 'payment sucessfull'
          }
        elsif response.code == '422'
          if response_data["messages"].present?
            render json: { status: false,  message: response_data["messages"] }
          end
        else
          order.update_column(:status, 'failed');
          if is_registered_user
            order.cart.update_attribute(:status, "payment_failed")
          else
            order.registration_form.update_attribute(:status, "payment_failed")
          end
          if response_data["status"] == 'AUTHORIZED'
            render json: { status: false,  message: response_data }
          else
            render json: { status: false,  message: response_data["messages"] }
          end
        end
      end
    rescue StandardError => e
      render json: {error: e.message}, status: :unprocessable_entity
    end
  end

  def zero_payment
    is_registered_user = session[:is_registered_user]
    mode_of_payment_id = params[:mode_of_payment_id]
    order_id           = params[:order_id]
    event_id           = params[:event_id]
    # binding.pry

    order = Order.where(id: order_id).first
    coupon_item = order.order_items.where.not(coupon_id: nil)

    if coupon_item.present?
      existing_numbers = OrderTransaction.where("transaction_id LIKE ?", "#{coupon_item.first.coupon.coupon_code}_%")
      order_transaction = nil
      if existing_numbers.present?
        existing_number = existing_numbers.first.transaction_id.split("-").second
        new_number = (existing_number.to_i + 1).to_s.rjust(existing_number.length, '0')
        order_transaction = OrderTransaction.create(
          transaction_id: "#{coupon_item.first.coupon.coupon_code}-#{new_number}",
          transaction_status: "COMPLETED",
          order_id: order.id
        )
      else
        order_transaction = OrderTransaction.create(
          transaction_id: "#{coupon_item.first.coupon.coupon_code}-001",
          transaction_status: "COMPLETED",
          order_id: order.id
        )
      end
      order.update_column(:status, 'paid')
      if current_user.present?
        coupon_code_usage = CouponCodeUsage.create(
          coupon_id: coupon_item.first.coupon.id,
          user_id: current_user.id
        )
        attendee = Attendee.find_by_slug session[:slug]
        if !attendee.present?
          render json: {
            status: false,
            message: 'Attendee can not found!. some thing went wrong'
          }
          return
        end

        transaction = Transaction.create(
          amount: order.total,
          external_status: "COMPLETED",
          transaction_status_type: TransactionStatusType.success,
          attendee_id: attendee.id,
          mode_of_payment_id: mode_of_payment_id,
          external_payment_id: order_transaction.transaction_id
        )

        order.update_columns(transaction_id: transaction.id, user_id: current_user.id)
        AttendeeMailer.registration_attendee_receipt(event_id, attendee, order).deliver

        coupon_item.first.coupon.decrement_remaining_usage

        render json: {
          user_id: current_user.id,
          status: true,
          order_id: order.id,
          transaction_id: transaction.id,
          time: transaction.created_at,
          amount: order.total,
          email: current_user.email,
          message: 'payment sucessfull'
        }
        return
      end

      if is_registered_user
        @user = order.user

        if !@user.confirmed_at?
          @user.confirm
        end

        # updating the password
        password = SecureRandom.base64(4)
        standard_attendee = AttendeeType.where(name: 'Standard Attendee').first

        @new_attendee = Attendee.create(
          email: order.user.email,
          user_id: order.user.id,
          is_member: order.user.is_member,
          event_id: event_id,
          password: password,
          first_name: @user.first_name,
          last_name: @user.last_name,
          attendee_type_id: standard_attendee.id,
          custom_filter_1: 'ATTENDEE',
          badge_name: @user.first_name
        )
        @new_attendee.qr_image
        roles        = @user.roles.pluck(:name)
        users_events = @user.users_events

        if roles.length == 1 && users_events.count == 1
          if users_events.first.user_event_roles.count == 0
            UserEventRole.find_or_create_by(
              role_id: @user.roles.first.id,
              users_event_id: users_events.first.id
            )
          end
        end

        if !roles.include?('Speaker')
          @user.password = password
          @user.password_confirmation = password
          @user.save

          user_data = {
            :user => {
              :password =>  password
            }
          }

          AttendeeMailer.registration_attendee_email_password(params[:event_id], @new_attendee, user_data).deliver
        end
      else
        users = User.where(email: order.registration_form.email)
        if users.present?
          @user = users.first

          if !@user.confirmed_at?
            @user.confirm
          end
        else
          password = SecureRandom.base64(4)

          user_data = {
            :user => {
              :password =>  password
            }
          }

          @user = User.create(
            email: order.registration_form.email,
            password: password,
            password_confirmation: password,
            first_name: order.registration_form.first_name,
            last_name: order.registration_form.last_name
          )
          if !@user.confirmed_at?
            @user.confirm
          end

          # create attendee
          @new_attendee = Attendee.new(order.registration_form.as_json(except: [:id, :status]))
          AttendeeMailer.registration_attendee_email_password(params[:event_id], @new_attendee, user_data).deliver
          # assign user
          standard_attendee = AttendeeType.where(name: 'Standard Attendee').first
          @new_attendee.attendee_type_id = standard_attendee.id
          @new_attendee.custom_filter_1 = 'ATTENDEE'
          @new_attendee.badge_name = @user.first_name
          @new_attendee.password = password
          @new_attendee.user_id = @user.id
          @new_attendee.save!
          @new_attendee.qr_image
        end
      end

      # coupon update and save the coupon usage details
      coupon_code_usage = CouponCodeUsage.new(coupon_id: coupon_item.first.coupon.id)
      if order.registration_form_id?
        coupon_code_usage.registration_form_id = order.registration_form_id
      end
      coupon_code_usage.user_id = @user.id
      coupon_code_usage.save
      coupon_item.first.coupon.decrement_remaining_usage

      attendee_role = Role.find_by(name: 'Attendee')

      users_event = UsersEvent.find_or_create_by(
        user_id: @user.id,
        event_id: event_id
      )
      # assigning event roles to the user
      UserEventRole.find_or_create_by(
        role_id: attendee_role.id,
        users_event_id: users_event.id
      )
      # assiging roles to the user
      UsersRole.find_or_create_by(
        user_id: @user.id,
        role_id: attendee_role.id
      )

      transaction = Transaction.create(
        amount: order.total,
        external_status: "COMPLETED",
        transaction_status_type: TransactionStatusType.success,
        attendee_id: @new_attendee.id,
        mode_of_payment_id: mode_of_payment_id,
        external_payment_id: order_transaction.transaction_id
      )
      order.update_columns(transaction_id: transaction.id, user_id: @user.id)

      if !is_registered_user
        order.registration_form.update_attribute(:status, "success")
      end
      render json: {
        user_id: @user.id,
        status: true,
        order_id: order.id,
        transaction_id: transaction.id,
        time: transaction.created_at,
        amount: order.total,
        email: @user.email,
        message: 'payment sucessfull'
      }

    end
  end

  def stripe_create_payment_order
    payment_intent     = params['payment_intent']
    mode_of_payment_id = params["mode_of_payment_id"]
    order = Order.find(params['orderId'])
    stripe_payment = Stripe::PaymentIntent.retrieve(params['payment_intent'])
    event_id = params[:event_id]

    if stripe_payment.status == 'succeeded'
      order.update_column(:status, 'paid');
      begin
        user = User.new(
          email: order.registration_form.email,
          password: order.registration_form.password,
          password_confirmation: order.registration_form.password,
          first_name: order.registration_form.first_name,
          last_name: order.registration_form.last_name
        )
        user.save!
        attendee_role = Role.find_by(name: 'Attendee')
        UsersRole.create!(
          user_id: user.id,
          role_id: attendee_role.id
        )
        # create attendee
        new_attendee = Attendee.new(order.registration_form.as_json(except: [:id, :status]))
        # assign user
        new_attendee.user_id = user.id
        new_attendee.save!
        # assign attendee to tarnsaction
        transaction = Transaction.create(
            amount: stripe_payment.amount_received/100,
            external_cust_id: stripe_payment.customer,
            external_status: stripe_payment.status,
            transaction_status_type: TransactionStatusType.success,
            attendee_id: new_attendee.id,
            external_payment_id: stripe_payment.id,
            mode_of_payment_id: mode_of_payment_id
          )

        order.update_column(:transaction_id, transaction.id)
        order.update_column(:user_id, user.id)
        order.registration_form.update_attribute(:status, "success")

        # deleteing the order if multiple orders get created
        # if order.registration_form.orders.length > 1
        #   order.registration_form.orders.each do |register_order|
        #     if register_order.id != order.id
        #       register_order.delete
        #     end
        #   end
        # end
        # order.
        notice = "Payment Successful"
      rescue => exception
        order.registration_form.update_attribute(:status, "paid_still_failed")
        notice = "Payment Paid, but something went wrong"
      end
    else
      order.update_column(:status, 'failed');
      order.registration_form.update_attribute(:status, "payment_failed")
			notice = "Something Went Wrong"
    end

    redirect_to "/#{event_id}/registrations/#{user.id}/#{order.registration_form_id}/payment_success", notice: notice
  end

  def stripe_complete_payment_registration_form
    @transaction = Transaction.find_by(external_payment_id: params["payment_intent"]);
    cart = RegistrationFormCart.find_by(id: params["cartId"])
    event_id = @transaction.mode_of_payment.event_id
		Stripe.api_key = @transaction.mode_of_payment.client_secret_key
		stripe_payment = Stripe::PaymentIntent.retrieve(params['payment_intent'])
    if stripe_payment.status == 'succeeded'
			@transaction.update(
        amount: stripe_payment.amount_received/100,
        external_status: stripe_payment.status,
        transaction_status_type: TransactionStatusType.success
      )
			cart.update_column(:status, 'payment_success')

      begin
        user = User.new(
          email: cart.registration_form.email,
          password: cart.registration_form.password,
          password_confirmation: cart.registration_form.password,
          first_name: cart.registration_form.first_name,
          last_name: cart.registration_form.last_name
        )
        user.save!
        # role
        attendee_role = Role.find_by(name: 'Attendee')
        UsersRole.create!(
          user_id: user.id,
          role_id: attendee_role.id
        )
        # create attendee - save
        # binding.pry
        new_attendee = Attendee.new(cart.registration_form.as_json(except: [:id, :status]))
        # assign user
        new_attendee.user_id = user.id
        new_attendee.save!
        @transaction.attendee = new_attendee
        # assign attendee to tarnsaction

        cart.create_order(@transaction, user)
        cart.registration_form.update_attribute(:status, "success")
        # cart.registration_form_cart_items.destroy_all
        notice = "Payment Successful"
      rescue => exception
        cart.registration_form.update_attribute(:status, "paid_still_failed")
        # some thing went wrong - paid but issue
        notice = "Payment Paid, but something went wrong"
      end
      redirect_to "/#{event_id}/registrations/#{user.id}/#{cart.registration_form_id}/payment_success", notice: notice
		else
      cart.registration_form.update_attribute(:status, "payment_failed")
			@transaction.update(external_status: stripe_payment.status)
			notice = "Something Went Wrong"
      # payment_failed
      redirect_to "/#{event_id}/registrations/#{user.id}/#{cart.registration_form_id}/payment_failed", notice: notice
		end
  end

  def payment_success
    is_registered_user      = session[:is_registered_user]
    @event    = Event.find params[:event_id]
    if is_registered_user
      register_user = User.find params[:form_id]
      cart = register_user.cart
      @cart_items = cart.cart_items
      session[:is_registered_user] = false
    else
      register_user = RegistrationForm.find(params[:form_id])
      cart = register_user.registration_form_cart
      @cart_items = cart.registration_form_cart_items
    end
    @cart_items.destroy_all
    @order = Order.where(user_id: params[:user_id]).last
    attendee = @order.user.attendee
    AttendeeMailer.registration_attendee_receipt(params[:event_id], attendee, @order).deliver
    redirect_to "/#{@event.id}/registrations/attendee/#{@order.user.attendee.id}/select_tag"
  end

  def payment_failed

  end

  def registered
    @event    = Event.find params[:event_id]
    @attendee = Attendee.find_by_slug(params[:id])
    @attendee_product = AttendeeProduct.find_by(attendee: @attendee)
    virtual_url = @attendee.event.virtual_portal_url
    @login_url = virtual_url + "/attendees/login_via_registration/#{@attendee.slug}"
    @attendee.blank? && (redirect_to "/#{params[:event_id]}/registrations" and return)
  end

  def verify
    @event_id     = params[:event_id]
    @user_attendee = Attendee.find_by_slug(params[:slug])
    if !!current_user.confirmed_at
      redirect_to "/#{params[:event_id]}/registrations/edit_profile/#{@user_attendee.slug}"
    end
  end

  def already_registered
    if user_signed_in?
      user_attendee = Attendee.where(
        event_id: params[:event_id],
        user_id: current_user.id,
        email: current_user.email
      ).first
      if user_attendee
        redirect_to "/"
      end
    else
      @user         = User.new
      event_id     = params[:event_id]
      @event = Event.find event_id

    end
  end

  def remove_bg_img
    event_file_type_id = EventFileType.find_by_name('registration_portal_image').id
    event_file         = EventFile.where(event_id:session[:event_id], event_file_type_id:event_file_type_id)
    event_file.destroy_all
    @settings          = Setting.return_registration_portal_settings(session[:event_id])
    @settings.body_background_image = ''
    @settings.save
    msg = 'Background Image removed successfully for registration portal.'
    redirect_to('/settings/registration_portal_settings', notice: msg)
  end

  def edit_profile
    @attendee = Attendee.find_by_slug params[:slug]
  end

  def update_profile
    @attendee = Attendee.find_by_slug(params[:attendee][:slug])
      if @attendee.update!(attendee_params)
        redirect_to "/#{params[:event_id]}/registrations/profile/#{params[:attendee][:slug]}", notice: 'Profile was successfully updated.'
      else
        redirect_to "/#{params[:event_id]}/registrations/edit_profile/#{params[:attendee][:slug]}", alert: @attendee.errors.full_messages.to_sentence
      end
  end

  def profile
    @attendee = Attendee.find_by_slug params[:slug]
    @event    = Event.find params[:event_id]
  end

  def agenda
    @event    = Event.find params[:event_id]
  end

  def speakers
    @event    = Event.find params[:event_id]
  end

  def exhibitors
    @event    = Event.find params[:event_id]
  end

  def sponsors
    @event    = Event.find params[:event_id]
  end

  def hotel_information
    @event    = Event.find params[:event_id]
  end

  def create_section
    key = (params[:key] == 'post_reg') ? 'no_of_content_sections_post_reg' : 'no_of_content_sections'
    if params["for_exhibitor"] == 'true'
      @settings = Setting.return_exhibitor_registration_portal_settings(session[:event_id])
      url_to_redirect = '/settings/exhibitor_registration_portal_settings'
    else
      @settings = Setting.return_registration_portal_settings(session[:event_id])
      url_to_redirect = '/settings/registration_portal_settings'
    end
    @settings.update_attribute(key.to_sym, @settings.send(key).to_i + 1)
    msg = 'New content section successfully added for registration portal.'
    redirect_to(url_to_redirect, notice: msg)
  end

  def create_column
    column_list = (params[:key] == 'post_reg') ? 'column_list_post_reg' : 'column_list'
    section_id = params[:section_id].to_i

    if params["for_exhibitor"] == 'true'
      @settings = Setting.return_exhibitor_registration_portal_settings(session[:event_id])
      url_to_redirect = '/settings/exhibitor_registration_portal_settings'
    else
      @settings = Setting.return_registration_portal_settings(session[:event_id])
      url_to_redirect = '/settings/registration_portal_settings'
    end

    @settings.json[column_list] = Array.new() if @settings.json[column_list].blank?
    @settings.json[column_list][section_id] = @settings.send(column_list)[section_id].to_i + 1
    @settings.save!
    msg = "New column successfully added for content section #{section_id}."
    redirect_to(url_to_redirect, notice: msg)
  end

  def remove_section

    if (params[:key] == 'post_reg')
      key = 'no_of_content_sections_post_reg'
      name = 'post_reg_section_container'
      column_list = 'column_list_post_reg'
    else
      key = 'no_of_content_sections'
      name = 'reg_section_container'
      column_list = 'column_list'
    end

    @settings = Setting.return_registration_portal_settings(session[:event_id])

    # Deletion of last section => last section has an id = no_of_content_sections
    section_id = @settings.send(key).to_i
    @settings.send(column_list) && @settings.send(column_list)[section_id] && @settings.send(column_list)[section_id].times do |j|
      col_name  = "#{name}#{section_id}_col#{j+1}"
      @settings.json[col_name] = ""
    end

    # Make its number of column 0
    @settings.json[column_list] && @settings.json[column_list][section_id] = 0

    # Decrease the total no_of_content_sections
    @settings.json[key] = @settings.send(key).to_i() - 1
    @settings.save!
    msg = 'Content section successfully removed.'
    redirect_to('/settings/registration_portal_settings', notice: msg)
  end

  def remove_column
    section_id = params[:section_id].to_i
    @settings = Setting.return_registration_portal_settings(session[:event_id])

    if (params[:key] == 'post_reg')
      name = 'post_reg_section_container'
      column_list = 'column_list_post_reg'
    else
      name = 'reg_section_container'
      column_list = 'column_list'
    end

    col_name  = "#{name}#{section_id}_col#{ @settings.column_list[section_id].to_i}"
    @settings.json[col_name] = ""
    @settings.json[column_list] && (@settings.json[column_list][section_id] = @settings.json[column_list][section_id].to_i - 1)
    @settings.save!
    msg = "Column successfully removed for content section #{section_id}."
    redirect_to('/settings/registration_portal_settings', notice: msg)
  end

  private

  def is_user_not_attendee user
    attendee_role   = Role.where(name: "Attendee").first_or_create
    user.role_ids.each do |user_role_id|
      return false if user_role_id == attendee_role.id
    end
    return true
  end

  def get_settings
    @settings = Setting.return_cached_settings_for_registration_portal({ event_id:params[:event_id] })
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :event_ids).
    merge({:role_ids => [].push(Role.find_by_name("Attendee").id)})
  end

  def attendee_params
    params.require(:attendee).permit(:email, :username, :first_name, :last_name, :honor_prefix, :honor_suffix, :title, :company, :biography, :business_unit, :business_phone,
     :mobile_phone, :country, :state, :city, :notes_email, :notes_email_pending, :temp_photo_filename, :photo_filename, :photo_event_file_id,
     :iattend_sessions, :assignment, :validar_url, :publish, :twitter_url, :facebook_url, :linked_in, :username, :attendee_type_id,
     :messaging_opt_out, :messaging_notifications_opt_out, :app_listing_opt_out, :game_opt_out, :first_run_toggle, :video_portal_first_run_toggle,
     :custom_filter_1, :custom_filter_2, :custom_filter_3, :pn_filters, :token, :tags_safeguard, :speaker_biography, :custom_fields_1, :survey_results,
     :travel_info, :table_assignment, :custom_fields_2, :custom_fields_3, :password, :is_member)
  end

  def require_login
    !user_signed_in? && (redirect_to "/#{params[:event_id]}/registrations/login_to_profile", :alert => "You need to sign in.")
  end

end
