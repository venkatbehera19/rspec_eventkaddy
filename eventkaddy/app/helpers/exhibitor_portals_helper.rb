module ExhibitorPortalsHelper
  def check_for_payment
    if !(current_user.first_name.present? && current_user.last_name.present?)
      redirect_to "/users/#{current_user.id}/account"
      return
    end
    if current_user.role? :exhibitor
      exhibitor = current_user.exhibitors.where(event_id: session[:event_id]).first
      if exhibitor
        exhibitor_product = Product.where(exhibitor_id: exhibitor.id).first
        if exhibitor_product.present?
          order_item        = OrderItem.where( item_id: exhibitor_product.id ).first
          orders = Order.includes(:order_items).where(order_items: { item_id: exhibitor_product.id}, orders: { status: 'paid'})
          if !orders.present?
            cart      = Cart.find_or_create_by(user: current_user)
            cart.cart_items.find_or_create_by(item_id: exhibitor_product.id, item_type: "Product", quantity: 1)
            redirect_to "/#{session[:event_id]}/exhibitor_portals/cart/#{cart.id}"
            return
          end
        end
      end
    end
  end
end
