class CreateSponsors < ActiveRecord::Migration[4.2]
  def change
    create_table :sponsors do |t|
	 t.integer :event_id
      t.string :company_name
      t.string :slogan
      t.string :description
	 t.string :address_line1
	 t.string :address_line2
	 t.string :city
	 t.string :state
	 t.string :zip
      t.string :url_web
      t.string :url_facebook
      t.string :url_twitter
      t.string :url_rss

      t.timestamps
    end
  end
end
