class CreateExhibitorFiles < ActiveRecord::Migration[4.2]
  def change
    create_table :exhibitor_files do |t|
      t.integer :event_id
      t.integer :exhibitor_id
      t.integer :event_file_id
      t.string :title
      t.string :description

      t.timestamps
    end
    add_index :exhibitor_files, :event_id
    add_index :exhibitor_files, :exhibitor_id
    add_index :exhibitor_files, :event_file_id
  end
end
