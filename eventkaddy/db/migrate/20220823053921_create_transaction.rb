class CreateTransaction < ActiveRecord::Migration[6.1]
  def change
    create_table :transactions do |t|
      t.decimal :amount
      t.string  :external_transaction_id
      t.string  :external_cust_id
      t.string  :external_status
      t.references :attendee
      t.references :product
      t.references :mode_of_payment
      t.references :transaction_status_type

      t.timestamps
    end
  end
end
