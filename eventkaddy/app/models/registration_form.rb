class RegistrationForm < ApplicationRecord
  has_one :registration_form_cart
  has_many :orders
  STATUS = ["pending", "success", "paid_still_failed", "payment_failed"]

  def create_order_items order
    is_member = order.registration_form.is_member
    total = 0
    self.registration_form_cart.registration_form_cart_items.each do |item|
      if item.item_type == 'Product'
        order_item = order.order_items.new(
          item_id: item.item_id, 
          item_type: item.item_type, 
          name: item.item.name, 
          price: is_member ? item.item.member_price : item.item.price, 
          quantity: item.quantity
        )
        if item.size?
          order_item.size = item.size
        end
        total = total + (is_member ? item.item.member_price * item.quantity : item.item.price * item.quantity )
        available_quantity = item.item.available_qantity - item.quantity
        item.item.update_column(:available_qantity, available_quantity)
      else
        order.order_items.new(
          item_id: item.item_id, 
          item_type: item.item_type, 
          name: item.item.products.first.name, 
          price: is_member ? item.item.products.first.member_price : item.item.products.first.price, 
          quantity: item.quantity
        )
        total = total + (is_member ? item.item.products.first.member_price * item.quantity : item.item.products.first.price * item.quantity)
        available_quantity = item.item.available_qantity - item.quantity
        item.item.update_column(:available_qantity, available_quantity)
      end
    end
    order.total = total
    order.save
    order
  end

  def create_order
    prev_order = Order.where(registration_form_id: self.id, status: "pending")
    created_order = nil;
    if prev_order.length != 0
      order = prev_order.first
      order.order_items.delete_all 
      created_order = create_order_items(order)
    else
      order = Order.create(registration_form_id: self.id, status: "pending")
      created_order = create_order_items(order)
    end
    self.registration_form_cart.registration_form_cart_items.delete_all
    created_order
	end

  def full_name 
    return "#{self.first_name} #{self.last_name}"
  end
end