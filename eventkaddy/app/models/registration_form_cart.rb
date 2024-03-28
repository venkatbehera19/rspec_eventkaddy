class RegistrationFormCart < ApplicationRecord
  belongs_to :registration_form
  has_many   :registration_form_cart_items, dependent: :destroy
  has_many   :transactions
  STATUS = ['on_product_select_page', 'on_payment_page', 'payment_success']
  def create_order(transaction, user)    
    order = Order.create!(user_id: user.id, transaction_id: transaction.id)
    total = 0
    self.registration_form_cart_items.each do |item|

      if item.item_type == 'Product'
        order.order_items.new(
          item_id: item.item_id, 
          item_type: item.item_type, 
          name: item.item.name, 
          price: item.item.price, 
          quantity: item.quantity
        )
        total = total + (item.item.price * item.quantity )

      else
        order.order_items.new(
          item_id: item.item_id, 
          item_type: item.item_type, 
          name: item.item.products.first.name, 
          price: item.item.products.first.price, 
          quantity: item.quantity
        )
        total = total + (item.item.products.first.price * item.quantity)
      end
    end
    order.total = total
    order.save!
	end
end