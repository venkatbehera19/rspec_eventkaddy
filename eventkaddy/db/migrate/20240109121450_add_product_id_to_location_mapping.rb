class AddProductIdToLocationMapping < ActiveRecord::Migration[6.1]
  def change
    add_column :location_mappings, :product_id, :integer
  end
end
