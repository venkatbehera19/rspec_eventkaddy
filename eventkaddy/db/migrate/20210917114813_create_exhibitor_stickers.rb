class CreateExhibitorStickers < ActiveRecord::Migration[6.1]
  def change
    create_table :exhibitor_stickers do |t|
      t.integer :event_id
      t.integer :exhibitor_id
      t.integer :event_file_id
      t.string :name
      t.string :link
      t.integer :z_index_position
      t.json :dimensions

      t.timestamps
    end
  end
end
