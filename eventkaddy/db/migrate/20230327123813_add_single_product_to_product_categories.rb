class AddSingleProductToProductCategories < ActiveRecord::Migration[6.1]
  def change
    add_column :product_categories, :single_product, :boolean
  end
end
