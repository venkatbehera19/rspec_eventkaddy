class AddStatusToCart < ActiveRecord::Migration[6.1]
  def change
    add_column :carts, :status, :string
    add_reference :carts, :transaction
  end
end
