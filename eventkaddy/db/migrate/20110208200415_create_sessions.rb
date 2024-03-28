class CreateSessions < ActiveRecord::Migration[4.2]
  def self.up
    create_table :sessions do |t|
			t.integer :event_id
			t.string :session_code
			t.boolean :session_cancelled
			t.string :title
			t.text :description
			t.integer :location_mapping_id
			t.string :tag_twitter
			t.date :date
			t.time :start_at
			t.time :end_at
			t.string :timezone_offset
			t.boolean :published
			t.integer :record_type
			t.string :video_iphone
			t.string :video_ipad
			t.string :video_android
			t.string :video_thumbnail
			t.string :price
			t.string :capacity
			t.string :credit_hours
			t.string :race_approved
			t.integer :program_type_id
			t.string :ticketed
			t.string :wvctv	 
			
			t.timestamps
    end
  end

  def self.down
    drop_table :sessions
  end
end
