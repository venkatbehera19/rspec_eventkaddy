class CreateEvents < ActiveRecord::Migration[4.2]
  def self.up
    create_table :events do |t|
      t.integer :org_id
      t.integer :logo_event_file_id
      t.string :name
      t.text :description
      t.string :splash_screen
      t.string :background_color
      t.string :logo
      t.string :email_title
      t.text :email_body
      t.string :facebook_title
      t.text :facebook_body
      t.string :twitter_body
      t.datetime :event_start_at
      t.datetime :event_end_at
      t.string :address_line1
      t.string :address_line2
      t.string :city
      t.string :state
      t.string :zip
      t.decimal :longitude
      t.decimal :latitude
      t.string :url_web
      t.string :url_facebook
      t.string :url_twitter
      t.string :url_rss
      t.boolean :exhibitors
      t.boolean :enhanced_listings
      t.boolean :sponsorship
      t.boolean :iphone
      t.boolean :android
      t.boolean :mobile_site
      t.boolean :touchscreen
      t.boolean :soma_record
      t.string :notification_UA_AK
      t.string :notification_UA_AMS
	  
      t.timestamps
    end
  end

  def self.down
    drop_table :events
  end
end
