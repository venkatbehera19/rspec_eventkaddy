class AddFreeBoothSelectProductToProductCategory < ActiveRecord::Migration[6.1]
  def change
    add_column :product_categories, :free_booth_select_product, :boolean, :default => false
  end
end
