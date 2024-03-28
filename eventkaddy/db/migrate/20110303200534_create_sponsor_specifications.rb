class CreateSponsorSpecifications < ActiveRecord::Migration[4.2]
  def self.up
    create_table :sponsor_specifications do |t|
      t.integer :exhibitor_id
      t.integer :sponsor_level_type
      t.boolean :banner_ad
      t.string :banner_ad_iphone
      t.string :banner_ad_android
      t.string :banner_ad_mobile
      t.string :banner_ad_home
      t.string :banner_ad_touch
      t.string :banner_ad_link

      t.timestamps
    end
  end

  def self.down
    drop_table :sponsor_specifications
  end
end
