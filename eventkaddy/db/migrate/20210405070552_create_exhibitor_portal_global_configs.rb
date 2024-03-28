class CreateExhibitorPortalGlobalConfigs < ActiveRecord::Migration[4.2]
  def change
    create_table :exhibitor_portal_global_configs do |t|
      t.integer :event_id
      t.integer :setting_id
      t.string :name
      t.boolean :default

      t.timestamps null: false
    end
  end
end
