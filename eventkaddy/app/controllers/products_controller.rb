class ProductsController < ApplicationController
  layout 'subevent_2013'
  before_action :authenticate_user!
  before_action :verify_as_admin
  before_action :set_event
  before_action :set_product, only: [:edit, :update, :show, :destroy, :add, :add_product_stripe]

  def index
    @products = Product.where(event: @event).order(:deleted, :name)
  end

  def new
    @product = Product.new

    map_type = MapType.find_by_map_type('Interactive Map')
    @event_map = EventMap.joins(location_mappings: :products)
                         .find_by(
                            map_type_id: map_type.id,
                            event_id: session[:event_id]
                          )
    location_mapping_with_product_associated = @event_map.location_mappings.joins(:location_mapping_products).select{|booth| booth.locked_by.nil? && booth.product_id.nil? }
    already_bought = LocationMapping.joins('LEFT JOIN order_items ON location_mappings.id = order_items.item_id').where(order_items: {item_type: 'LocationMapping'}).uniq
    @available_location_mapping = location_mapping_with_product_associated - already_bought

  end

  def create
    location_mapping_id = params[:booth_for_additional_sponser]
    @product = Product.new(product_param)
    exhibitor_user_booth   = ProductCategory.where(event_id: product_param[:event_id], iid: 'exhibitor_user_booth').first
    sponsorship_with_booth = ProductCategory.where(event_id: product_param[:event_id], iid: 'sponsorship_with_booth').first

    if params[:product][:product_categories_id].to_i == exhibitor_user_booth.id
      @product.exhibitor_id = params[:exhibitor_id]
    end

    @product.iid = @product.name.downcase.gsub(' ', '_')
    sponsor_level_types_ids = params[:sponsor_level_type]
    if @product.save
      if sponsor_level_types_ids.present?
        sponsor_level_types_ids.each do |id|
          sponsor_product = SponsorLevelTypeProduct.find_or_create_by(product: @product, sponsor_level_type_id: id)
        end
      end
      @product.upload_image(params[:image_event_file_id]) if params[:image_event_file_id].present?
      if params[:product_categories_id] == sponsorship_with_booth.id
        location_mapping = LocationMapping.where( id: location_mapping_id ).first
        location_mapping.update_column("product_id", @product.id) if location_mapping.present?
      end
      redirect_to products_path, notice: "Product Created Successfully"
    else
      render :new
    end
  end

  def edit
    map_type = MapType.find_by_map_type('Interactive Map')
    @event_map = EventMap.joins(location_mappings: :products)
                         .find_by(
                            map_type_id: map_type.id,
                            event_id: session[:event_id]
                          )
    location_mapping_with_product_associated = @event_map.location_mappings.joins(:location_mapping_products).select{|booth| booth.locked_by.nil? }
    already_bought = LocationMapping.joins('LEFT JOIN order_items ON location_mappings.id = order_items.item_id').where(order_items: {item_type: 'LocationMapping'}).uniq
    @available_location_mapping = location_mapping_with_product_associated - already_bought
    @selected_location_mapping  = LocationMapping.where( product_id: @product.id ).first
  end

  def update
    exhibitor_user_booth   = ProductCategory.where(event_id: product_param[:event_id], iid: 'exhibitor_user_booth').first
    if params[:exhibitor_id].present?
     if  params[:product][:product_categories_id].to_i == exhibitor_user_booth.id
      @product.exhibitor_id = params[:exhibitor_id]
     end
    end

    if @product.update(product_param)
      sponsor_level_types_ids = params[:sponsor_level_type]
      if sponsor_level_types_ids.present?
        sponsor_products = SponsorLevelTypeProduct.where(product: @product)
        sponsor_product_present = []
        sponsor_level_types_ids.each do |id|
          sponsor_product = SponsorLevelTypeProduct.find_or_initialize_by(product: @product, sponsor_level_type_id: id)
          sponsor_product.save if sponsor_product.id.nil?
          sponsor_product_present.push(sponsor_product.id)
        end
        to_be_deleted = sponsor_products.ids - sponsor_product_present
        SponsorLevelTypeProduct.where(id: to_be_deleted).destroy_all
      end
      @product.upload_image(params[:image_event_file_id]) if params[:image_event_file_id].present?
      # if diffrent location mappings id, then updating the location mapping
      @location_mapping_product = LocationMapping.where(product_id: @product.id).first
      if @location_mapping_product.present?
        location_mapping_id = params[:booth_for_additional_sponser].to_i
        if @location_mapping_product.id != location_mapping_id
          location_mapping = LocationMapping.where( id: location_mapping_id ).first
          location_mapping.update_column("product_id", @product.id) if location_mapping.present?
          @location_mapping_product.update_column("product_id", nil)
        else
        end
      end
      redirect_to products_path, notice: "Product Updated Successfully"
    else
      render :edit
    end
  end

  def success
    product = Product.find params[:id]
    @p = Product
    .select("users.first_name","users.last_name","users.email","products.event_id as event_id", "products.name as item_name", "products.gl_code", "orders.id as order_id", "orders.status", "orders.created_at as orders_created_at", "orders.updated_at as orders_updated_at", "orders.registration_form_id", "transactions.amount", "transactions.created_at as transaction_created_at", "transactions.external_status", "order_items.name as order_item_name", "order_items.quantity as order_item_quantity", "order_items.price as order_item_price", "order_items.item_type as order_item_type", "order_items.item_id as order_item_id", "coupons.amount as coupon_amount", "coupons.coupon_code", "coupons.coupon_name", "coupons.id as coupon_id")
    .joins("INNER JOIN order_items ON order_items.item_id = products.id")
    .joins("INNER JOIN orders ON orders.id = order_items.order_id")
    .joins("LEFT JOIN users ON users.id = orders.user_id")
    .joins("LEFT JOIN transactions ON transactions.id = orders.transaction_id")
    .joins("LEFT JOIN coupons ON coupons.id = order_items.coupon_id")
      .where(id: product.id, orders: {
        status: 'paid'
      })
    @result = @p.as_json(only: [ :name, :event_id], methods: [:first_name, :last_name, :email, :item_name, :order_id, :status, :registration_form_id, :orders_created_at, :orders_updated_at, :gl_code, :amount, :transaction_created_at, :external_status, :order_item_price, :order_item_quantity, :order_item_name, :event_id, :order_item_type, :order_item_id, :coupon_amount, :coupon_code, :coupon_name, :coupon_id])
  end

  def refunded
    product = Product.find params[:id]
    @p = Product
    .select("users.first_name","users.last_name","users.email","products.event_id as event_id", "products.name as item_name", "products.gl_code", "orders.id as order_id", "orders.status", "orders.created_at as orders_created_at", "orders.updated_at as orders_updated_at", "orders.registration_form_id", "transactions.amount", "transactions.created_at as transaction_created_at", "transactions.external_status", "order_items.name as order_item_name", "order_items.quantity as order_item_quantity", "order_items.price as order_item_price", "order_items.item_type as order_item_type", "order_items.item_id as order_item_id", "coupons.amount as coupon_amount", "coupons.coupon_code", "coupons.coupon_name", "coupons.id as coupon_id")
    .joins("INNER JOIN order_items ON order_items.item_id = products.id")
    .joins("INNER JOIN orders ON orders.id = order_items.order_id")
    .joins("LEFT JOIN users ON users.id = orders.user_id")
    .joins("LEFT JOIN transactions ON transactions.id = orders.transaction_id")
    .joins("LEFT JOIN coupons ON coupons.id = order_items.coupon_id")
      .where(id: product.id, orders: {
        status: 'refund_completed'
      })
    @result = @p.as_json(only: [ :name, :event_id], methods: [:first_name, :last_name, :email, :item_name, :order_id, :status, :registration_form_id, :orders_created_at, :orders_updated_at, :gl_code, :amount, :transaction_created_at, :external_status, :order_item_price, :order_item_quantity, :order_item_name, :event_id, :order_item_type, :order_item_id, :coupon_amount, :coupon_code, :coupon_name, :coupon_id])
  end

  def unorder
    @products = Product
    .joins(:product_category)
    .where(event_id: session[:event_id])
    .where.not(
      OrderItem.select(1)
      .where("order_items.item_id = products.id").arel.exists
    )
  end

  def show
    product = Product.find params[:id]

    @products = Product
    .select("users.first_name","users.last_name","users.email","products.event_id as event_id", "products.name as item_name", "products.gl_code", "orders.id as order_id", "orders.status", "orders.created_at as orders_created_at", "orders.updated_at as orders_updated_at", "orders.registration_form_id", "transactions.amount", "transactions.created_at as transaction_created_at", "transactions.external_status", "order_items.name as order_item_name", "order_items.quantity as order_item_quantity", "order_items.price as order_item_price", "order_items.item_type as order_item_type", "order_items.item_id as order_item_id", "coupons.amount as coupon_amount", "coupons.coupon_code", "coupons.coupon_name", "coupons.id as coupon_id")
    .joins("INNER JOIN order_items ON order_items.item_id = products.id")
    .joins("INNER JOIN orders ON orders.id = order_items.order_id")
    .joins("LEFT JOIN users ON users.id = orders.user_id")
    .joins("LEFT JOIN transactions ON transactions.id = orders.transaction_id")
    .joins("LEFT JOIN coupons ON coupons.id = order_items.coupon_id")
      .where(id: product.id, orders: {
        status: ['paid', 'refund_completed']
      })

    @result = @products.as_json(only: [ :name, :event_id], methods: [:first_name, :last_name, :email, :item_name, :order_id, :status, :registration_form_id, :orders_created_at, :orders_updated_at, :gl_code, :amount, :transaction_created_at, :external_status, :order_item_price, :order_item_quantity, :order_item_name, :event_id, :order_item_type, :order_item_id, :coupon_amount, :coupon_code, :coupon_name, :coupon_id])
  end

  def destroy
    @product.update(deleted: true, deleted_at: DateTime.now, deleted_by: current_user.id)
    redirect_to products_path, notice: "Product Deleted"
  end

  def add
    @product.update(deleted: false, deleted_at: nil, deleted_by: nil)
    redirect_to products_path, notice: "Product Added"
  end

  # def add_product_stripe
  #   payment_mode = ModeOfPayment.find_by(name: 'Stripe')
  #   stripe_key = payment_mode.client_secret_key if payment_mode
  #   if stripe_key
  #     Stripe.api_key = stripe_key
  #     stripe_product = Stripe::Product.create({name: @product.description, default_price_data: {currency: 'USD', unit_amount_decimal: (@product.price * 100).to_i }})
  #     if stripe_product.id
  #       @product.update(stripe_product_id: stripe_product.default_price)
  #       msg = 'Product Added To Stripe'
  #     else
  #       msg = 'Product Not Added To Stripe'
  #     end
  #   else
  #     msg = 'Stripe Key Not Found'
  #   end
  #   redirect_to products_path, notice: msg
  # end
  def reorder_product
    @is_super_admin = current_user.role? 'SuperAdmin'
    @all_product = Product.where(event_id: session[:event_id]).order(:order)
  end

  def update_order_product
    event_id = session[:event_id]
    products = params[:products]
    products.each do |key, product|
      products = Product.where(event_id: event_id, id: product["product_id"].to_i ).first
      products.update(order: product["order"].to_i)
    end
    render json: {notice: "ok"}, status: 200
  end

  private

  def product_param
    params.require(:product).permit(:name, :description, :event_id, :price, :product_categories_id, :image_event_file_id, :start_date, :end_date, :quantity, :member_price, :has_sizes, :gl_code, :maximum_discount_staff, :maximum_complimentary_staff)
  end

  def verify_as_admin
    raise "Your not authorized for this action" unless  (current_user.role?("Client") || current_user.role?("SuperAdmin"))
  end

  def set_event
    if session[:event_id].present?
      @event = Event.find_by(id: session[:event_id])
    end

    redirect_to root_url if @event.nil?
  end

  def set_product
    @product = Product.find_by(id: params[:id], event: @event)
  end

end
