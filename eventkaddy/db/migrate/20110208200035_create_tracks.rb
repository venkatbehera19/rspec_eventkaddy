class CreateTracks < ActiveRecord::Migration[4.2]
	def self.up

		create_table :tracks do |t|
			
			t.string :name
			t.text :description
			t.integer :event_id 
			t.string :track_color
	
			t.timestamps
		end
	end

	def self.down
		drop_table :tracks
		end
end
