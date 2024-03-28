class CreateOrganizations < ActiveRecord::Migration[4.2]
  def self.up
    create_table :organizations do |t|
      t.string :name
      t.text :description
      t.string :address_line1
      t.string :address_line2
      t.string :city
      t.string :zip
      t.string :state
      t.string :country
      t.string :contact_name
      t.string :contact_phone
      t.string :contact_mobile
      t.string :url_web
      t.string :url_twitter
      t.string :url_facebook

      t.timestamps
    end
  end

  def self.down
    drop_table :organizations
  end
end
