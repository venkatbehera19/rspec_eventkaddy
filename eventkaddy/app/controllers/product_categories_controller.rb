class ProductCategoriesController < ApplicationController
  layout 'subevent_2013'
  before_action :authenticate_user!
  before_action :verify_as_admin_or_client

  # load_and_authorize_resource
  before_action :set_event
  before_action :set_product_category, only: [:edit, :update, :show, :destroy, :add, :reorder_product_category, ]

  def index
  	@product_categories = ProductCategory.where(event: @event)
  end

  def new
    @product_categories = ProductCategory
                        .where(event: @event)
  	@product_category = ProductCategory.new(event: @event)
  end

  def create
    @product_category = ProductCategory.new(product_category_param)
    @product_category.iid = @product_category.name.downcase.gsub(' ', '_')
    if @product_category.save
      redirect_to product_category_path(@product_category), notice: "Product Category Created Successfully"
    else
      render :new
    end
  end

  def edit
    @product_categories = ProductCategory
                        .where(event: @event)
                        .where.not(id: @product_category.id)

    @category_exclusions_ids = CategoryExclusion.where(category_id: @product_category.id).pluck(:excluded_category_id)
  end

  def update
    if @product_category.update(product_category_param)
      CategoryExclusion.where(category_id: @product_category.id).delete_all
      if params[:exclude_category].present?
        params[:exclude_category].each do |category|
          CategoryExclusion.find_or_create_by(
            category_id: @product_category.id,
            excluded_category_id: category)
        end
      end
      redirect_to product_category_path(@product_category), notice: "Product Category Updated Successfully"
    else
      render :edit
    end
  end

  def show
  end

  def create_default_product_categories
    ProductCategory.create_product_category(session[:event_id])
    redirect_to '/product_categories'
  end

  def destroy
    is_product_deleted_false = false
    @product_category.products.each do |product|

      if product.deleted.nil? || product.deleted == false
        is_product_deleted_false = true;
        break
      end
    end

    if is_product_deleted_false
      left_deleted_product_count = 0
      @product_category.products.each do |product|

        if product.deleted.nil? || product.deleted == false
          left_deleted_product_count = left_deleted_product_count + 1
        end
      end
      redirect_to '/product_categories', alert: "Please delete the remaining #{left_deleted_product_count} product first"

    else
      @product_category.update(
        deleted: true,
        deleted_at: DateTime.now,
        deleted_by: current_user.id
      )
      redirect_to '/product_categories', notice: "Product Category Deleted"
    end
  end

  def add
    @product_category.update(
      deleted: false,
      deleted_at: nil,
      deleted_by: nil
    )
    redirect_to '/product_categories', notice: "Product Category Added"
  end

  def reorder_product_category
    @is_super_admin = current_user.role? 'SuperAdmin'
    @all_product_category = ProductCategory.where(event_id: session[:event_id]).order(:order)
  end

  def update_order_product_category
    event_id = session[:event_id]
    product_categories = params[:product_categories]
    product_categories.each do |key, product_category|
      product = ProductCategory.where(event_id: event_id, id: product_category["product_id"].to_i ).first
      product.update(order: product_category["order"].to_i)
    end
    render json: {notice: "ok"}, status: 200
  end

  private

  def product_category_param
  	params.require(:product_category).permit(:name, :event_id, :multi_select_product, :single_product, :free_booth_select_product)
  end

  def verify_as_admin_or_client
    raise "Your not authorized for this action" unless  (current_user.role?("Client") || current_user.role?("SuperAdmin"))
  end

  def set_event
  	if session[:event_id].present?
  		@event = Event.find_by(id: session[:event_id])
  	end

  	redirect_to root_url if @event.nil?
  end

  def set_product_category
  	@product_category = ProductCategory.find_by(id: params[:id], event: @event)
  end

end
