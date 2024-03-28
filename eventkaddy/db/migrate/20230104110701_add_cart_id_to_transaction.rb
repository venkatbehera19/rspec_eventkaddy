class AddCartIdToTransaction < ActiveRecord::Migration[6.1]
  def change
    add_column :transactions, :cart_id, :integer
  end
end
