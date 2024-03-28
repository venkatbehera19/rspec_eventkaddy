class AddMultiSelectProductToProductCategory < ActiveRecord::Migration[6.1]
  def change
    add_column :product_categories, :multi_select_product, :boolean, :default => false
  end
end
