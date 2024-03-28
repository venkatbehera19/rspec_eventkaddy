class CreateLocationMappingTypes < ActiveRecord::Migration[4.2]
  def self.up
    create_table :location_mapping_types do |t|
      t.string :type_name

      t.timestamps
    end
  end

  def self.down
    drop_table :location_mapping_types
  end
end
