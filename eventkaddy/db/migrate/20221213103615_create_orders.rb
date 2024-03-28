class CreateOrders < ActiveRecord::Migration[6.1]
  def change
    create_table :orders do |t|
      t.string :status

      t.references :user
      t.references :transaction
      t.timestamps
    end
  end
end
