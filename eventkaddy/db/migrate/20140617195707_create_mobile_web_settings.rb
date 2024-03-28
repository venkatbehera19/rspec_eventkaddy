class CreateMobileWebSettings < ActiveRecord::Migration[4.2]
  def change
    create_table :mobile_web_settings do |t|
      t.integer :event_id
      t.integer :type_id
      t.boolean :enabled
      t.text :content

      t.timestamps
    end
  end
end
