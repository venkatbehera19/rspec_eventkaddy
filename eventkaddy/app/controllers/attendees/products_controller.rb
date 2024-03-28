class ::Attendees::ProductsController < ::ApplicationController
    layout :set_layout

    before_action :get_settings, only: [:index]

    def index 
      @user = current_user
      @cart = current_user.cart
      if @cart.nil?
        @cart = @user.create_cart
      end
      @cart_items = @cart.cart_items
      product_category_ids = @settings.product_categories_ids
      @product_category = ProductCategory.where(id: product_category_ids);
      @product_category_with_product = ProductCategory.joins(:products).where(id: product_category_ids).order(:order).uniq
      @tab_type_ids  = TabType.where(portal:"attendee").pluck(:id)
      tabs          = Tab.where(
        event_id: session[:event_id], 
        tab_type_id: @tab_type_ids
      ).order(:order)
      @is_attendee = current_user.role? :attendee
      @current_tab = tabs.first
    end

    private 
    def get_settings
      @settings = Setting.return_cached_settings_for_registration_portal({ event_id: current_user.attendee.event_id })
    end

    def set_layout
      @current_user = current_user
      if current_user.role? :attendee then 
        'attendeeportal'
      else
        'subevent_2013' 
      end
    end

  end
