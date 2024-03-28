module AttendeePortalsHelper 
  def check_product_for (product, cart)
    quantity = 0;
    cart.cart_items.each do |item| 
      if item.item_id == product.id 
        quantity = item.quantity
      end
    end
    quantity
  end
end