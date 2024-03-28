class DeleteOrderForAttendeeWorker 
  include Sidekiq::Worker
  queue_as :delete_order_for_attendee_queue
  sidekiq_options retry: 0

  def perform(order_id)
    order = Order.where(id: order_id).first
    if order.present?
      if order.status == "pending"
        order.update_column(:status, "failed")
        # adding quantity
        order.order_items.includes(:item).each do |order_item| 
          ordered_quantity = order_item.quantity 
          available_qantity = order_item.item.available_qantity
          updated_quantity = available_qantity + ordered_quantity
          order_item.item.update_column(:available_qantity, updated_quantity)
        end
      end
    end
  end
end