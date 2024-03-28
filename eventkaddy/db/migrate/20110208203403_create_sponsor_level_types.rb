class CreateSponsorLevelTypes < ActiveRecord::Migration[4.2]
  def self.up
    create_table :sponsor_level_types do |t|
      t.string :sponsor_type

      t.timestamps
    end
  end

  def self.down
    drop_table :sponsor_level_types
  end
end
