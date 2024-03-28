class CreateSettings < ActiveRecord::Migration[4.2]
  def change
    create_table :settings do |t|
      t.integer :event_id
      t.integer :setting_type_id
      t.text :json

      t.timestamps
    end
  end
end
