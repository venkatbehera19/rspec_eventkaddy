class AddAvailableQuantityToProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :available_qantity, :integer, :default => 0
  end
end
