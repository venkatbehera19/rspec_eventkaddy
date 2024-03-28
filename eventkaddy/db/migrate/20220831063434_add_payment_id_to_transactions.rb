class AddPaymentIdToTransactions < ActiveRecord::Migration[6.1]
  def change
    add_column :transactions, :external_payment_id, :string
  end
end
