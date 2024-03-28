class CreateTransactionStatusType < ActiveRecord::Migration[6.1]
  def change
    create_table :transaction_status_types do |t|
      t.string :iid
      t.string :description
      t.timestamps
    end
  end
end
