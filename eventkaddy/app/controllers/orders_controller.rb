class OrdersController < ApplicationController

  def destroy
    order = Order.find params[:id]
    if order.transaction_id?
      transaction = order.transaction_detail
      transaction.delete

    end
    if order.order_items.present?
      order.order_items.delete_all
    end
    if order.delete
      redirect_to '/purchases/item_purchases', notice: "Order and Transactions Deleted"
    end
  end
end
