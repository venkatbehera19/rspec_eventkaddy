module Exhibitors
  class CartItemsController < ApplicationController

    def destroy
      event_id     = params[:event_id]
      cart_id      = params[:cart_id]
      cart         = Cart.find cart_id
      cart_item_id = params[:id]
      cart_item    = cart.cart_items.find_by(id: cart_item_id)

      if cart_item.item_type == 'LocationMapping'
        cart_item.delete
        if cart.cart_items.present?
          redirect_to "/#{event_id}/exhibitor_registrations/cart/#{cart.id}", notice: "Booth Delete Sucessfully."
        else
          redirect_to "/#{event_id}/exhibitor_registrations/payment/#{cart.user.id}/select_booth", notice: 'Cart is Empty.'
        end
      else
        cart_item.delete
        if cart.cart_items.present?
          redirect_to "/#{event_id}/exhibitor_registrations/cart/#{cart.id}", notice: "Item Delete Sucessfully."
        else
          redirect_to "/#{event_id}/exhibitor_registrations/payment/#{cart.user.id}/select_booth", notice: 'Cart is Empty.'
        end
      end
    end

    def update
      quantity      = params[:quantity].to_i
      event_id      = params[:event_id]
      product_id    = params[:product_id]
      cart_item_id  = params[:id]
      cart_id       = params[:cart_id]

      product   = Product.where(id: product_id).first
      cart      = Cart.find cart_id
      cart_item = cart.cart_items.find_by(id: cart_item_id)

      if !product
        cart_item.delete
        redirect_to "/#{event_id}/exhibitor_registrations/cart/#{cart.id}", notice: "Product Unavailable."
        return
      end

      if !product.available?(quantity)
        redirect_to "/#{event_id}/exhibitor_registrations/cart/#{cart.id}", notice: "Unable to update the Product "
        return
      end

      if quantity == 0
        cart_item.delete
        redirect_to "/#{event_id}/exhibitor_registrations/cart/#{cart.id}", notice: "Product removed from cart."
        return
      end

      if quantity < 0
        redirect_to "/#{event_id}/exhibitor_registrations/cart/#{cart.id}", notice: "Unable to update the Product "
        return
      end

      cart_item.update_attribute(:quantity, quantity)
      redirect_to "/#{event_id}/exhibitor_registrations/cart/#{cart.id}", notice: "Product Quantity updated succesfully."
    end

  end
end
