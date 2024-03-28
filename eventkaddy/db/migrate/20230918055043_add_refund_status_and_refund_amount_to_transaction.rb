class AddRefundStatusAndRefundAmountToTransaction < ActiveRecord::Migration[6.1]
  def change
    add_column :transactions, :external_refund_status, :string
    add_column :transactions, :external_refund_amount, :decimal, precision: 10
    add_column :transactions, :external_refund_completion_at, :datetime
  end
end
