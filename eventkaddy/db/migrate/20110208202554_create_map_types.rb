class CreateMapTypes < ActiveRecord::Migration[4.2]
  def self.up
    create_table :map_types do |t|
      t.string :map_type

      t.timestamps
    end
  end

  def self.down
    drop_table :map_types
  end
end
