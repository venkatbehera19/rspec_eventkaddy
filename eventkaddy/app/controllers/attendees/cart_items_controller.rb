module Attendees 
  class CartItemsController < ApplicationController
    layout :set_layout

    before_action :get_settings, only: [:index, :update]

    def index 
      get_settings
      @cart = current_user.cart
      @user = current_user
      @total = @cart.cart_items.reduce(0) do |sum, item|
                if item.item_type == 'Product'
      						sum = sum + (item.item.price * item.quantity )
      					else  
      						sum = sum + (item.item.products.first.price * item.quantity)
      					end  
      					sum
      				end
    end

    def update
      @is_payment_page        = params[:is_payment_page]
      cart_id                 = params[:id]
      product_id              = params[:product_id]
      product_quantity        = params[:quantity]
      user_id                 = params[:user_id]
      product                 = Product.find(product_id)
      @cart                   = current_user.cart
      cart_item               = @cart.cart_items.where(item_id: product_id).first
      product_category        = product.product_category
      is_multi_select_product = product_category.multi_select_product
      is_single_product       = product_category.single_product
      product_cart_items      = @cart.cart_items
      product_category_ids    = @settings.product_categories_ids
      
      

      @product_category_with_product = ProductCategory.joins(:products).where(id: product_category_ids).order(:order).uniq

      if cart_item.present?
        
        if is_multi_select_product
          cart_item.update_attribute(:quantity, product_quantity)
          @cart.reload
          @total = @cart.cart_items.reduce(0) do |sum, item|
            if item.item_type == 'Product'
              sum = sum + (item.item.price * item.quantity )
            else  
              sum = sum + (item.item.products.first.price * item.quantity)
            end  
            sum
          end
          if cart_item.quantity == 0
            cart_item.delete 
            if @is_payment_page
              respond_to do |format|
                format.js { render "/registrations/update_cart" }
              end
            else  
              respond_to do |format|
                format.js { render "/registrations/update_cart" }
              end
            end
            
          else
            if @is_payment_page
              respond_to do |format|
                format.js { render "/registrations/update_cart" }
              end
            else
              respond_to do |format|
                format.js { render "/registrations/update_cart" }
              end
            end
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
          @cart.cart_items.create(
            item_id: product_id, 
            item_type: 'Product'
          )
          @cart.reload
          @total = @cart.cart_items.reduce(0) do |sum, item|
            if item.item_type == 'Product'
              sum = sum + (item.item.price * item.quantity )
            else  
              sum = sum + (item.item.products.first.price * item.quantity)
            end  
            sum
          end
          respond_to do |format|
            format.js { render "/registrations/update_cart" } 
          end

        else
          @cart.cart_items.create(
            item_id: product_id, 
            item_type: 'Product'
          )
          @total = @cart.cart_items.reduce(0) do |sum, item|
            if item.item_type == 'Product'
              sum = sum + (item.item.price * item.quantity )
            else  
              sum = sum + (item.item.products.first.price * item.quantity)
            end  
            sum
          end
          respond_to do |format|
            format.js { render "/registrations/update_cart" }
          end
        end
      end
    end

    def destroy
      product_id              = params[:product_id]
      @cart                   = current_user.cart
      user                    = current_user
      item = @cart.cart_items.find_by(item_id: product_id);
      item.delete
      @total = @cart.cart_items.reduce(0) do |sum, item|
        if item.item_type == 'Product'
          sum = sum + (item.item.price * item.quantity )
        else  
          sum = sum + (item.item.products.first.price * item.quantity)
        end  
        sum
      end
      updated_cart_items_length = @cart.cart_items.length
      if updated_cart_items_length == 0
        respond_to do |format|
          format.js { render "/registrations/delete_item"}
        end
      else
        respond_to do |format|
          format.js { render "/registrations/delete_item"}
        end
      end
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
end