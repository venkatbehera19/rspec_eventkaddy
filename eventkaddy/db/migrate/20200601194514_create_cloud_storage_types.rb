class CreateCloudStorageTypes < ActiveRecord::Migration[4.2]
  def change
   create_table :cloud_storage_types do |t|
      t.string :name
      t.string :provider
      t.string :region
      t.string :bucket
      t.string :link_expiration_duration
      t.boolean :presigned_url
      t.timestamps
    end
  end
end
