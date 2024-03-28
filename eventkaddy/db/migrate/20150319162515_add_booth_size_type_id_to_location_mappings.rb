class AddBoothSizeTypeIdToLocationMappings < ActiveRecord::Migration[4.2]
  def change
    add_column :location_mappings, :booth_size_type_id, :integer
  end
end
