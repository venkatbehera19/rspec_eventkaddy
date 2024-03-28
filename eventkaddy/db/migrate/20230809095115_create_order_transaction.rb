class CreateOrderTransaction < ActiveRecord::Migration[6.1]
  def change
    create_table :order_transactions do |t|
      t.integer :order_id
      t.string  :transaction_id
      t.string  :transaction_status
      t.timestamps
    end
  end
end
