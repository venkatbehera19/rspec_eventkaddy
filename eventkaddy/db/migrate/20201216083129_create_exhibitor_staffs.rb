class CreateExhibitorStaffs < ActiveRecord::Migration[4.2]
  def change
    create_table :exhibitor_staffs do |t|
      t.integer :event_id
      t.references :exhibitor, null: false, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.string :title
      t.string :email
      t.string :business_phone
      t.string :mobile_phone
      t.integer :staff_photo_file_id
      t.string :url_twitter
      t.string :url_facebook
      t.string :url_linkedin      
      t.string :url_youtube
      t.string :url_instagram
      t.string :url_tiktok
      t.text :biography
      t.text :interests
      t.integer :user_id
      t.boolean :is_featured
      t.binary :slug, limit: 36
      t.boolean :is_exhibitor, :default => false

      t.timestamps null: false
    end
    add_index :exhibitor_staffs, :slug
    add_index :exhibitor_staffs, :event_id
    add_index :exhibitor_staffs, :exhibitor_id
    add_index :exhibitor_staffs, :user_id
  end
end
