class AddWidthAndHeightToLocationMappings < ActiveRecord::Migration[6.1]
  def change
    add_column :location_mappings, :width, :integer
    add_column :location_mappings, :height, :integer
  end
end
