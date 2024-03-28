class AddDeleteFieldToProductCategory < ActiveRecord::Migration[6.1]
  def change
    add_column :product_categories, :deleted, :boolean
    add_column :product_categories, :deleted_at, :datetime
    add_column :product_categories, :deleted_by, :integer
  end
end
