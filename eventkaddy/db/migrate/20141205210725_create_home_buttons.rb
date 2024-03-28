class CreateHomeButtons < ActiveRecord::Migration[4.2]
  def change
    create_table :home_buttons do |t|
      t.integer :event_id
      t.integer :home_button_type_id
      t.integer :event_file_id
      t.string :name
      t.string :icon_button_name
      t.integer :position

      t.timestamps
    end
  end
end
