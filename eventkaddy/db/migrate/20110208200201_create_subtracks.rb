class CreateSubtracks < ActiveRecord::Migration[4.2]
  def self.up
    create_table :subtracks do |t|
      
      t.string :name
      t.text :description
	  t.integer :track_id

      t.timestamps
    end
  end

  def self.down
    drop_table :subtracks
  end
end
