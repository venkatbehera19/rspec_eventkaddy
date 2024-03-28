class CreateExhibitors < ActiveRecord::Migration[4.2]
  def self.up
    create_table :exhibitors do |t|
      t.integer :location_mapping_id
      t.integer :event_id
      t.integer :user_id
      t.integer :logo_event_file_id
      t.integer :sponsor_level_type_id
      t.string :company_name
      t.text :description
      t.string :logo
      t.string :address_line1
      t.string :address_line2
      t.string :city
      t.string :zip
      t.string :state
      t.string :country
      t.string :email
      t.string :phone
      t.string :fax
      t.string :url_web
      t.string :url_twitter
      t.string :url_facebook
      t.string :url_linkedin
      t.string :url_rss
      t.text :message
      t.boolean :is_sponsor

      t.timestamps
    end
  end

  def self.down
    drop_table :exhibitors
  end
end
