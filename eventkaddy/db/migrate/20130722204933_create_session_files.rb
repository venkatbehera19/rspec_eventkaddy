class CreateSessionFiles < ActiveRecord::Migration[4.2]
  def change
    create_table :session_files do |t|
      t.integer :event_id
      t.integer :session_id
      t.string :title
      t.text :description

      t.timestamps
    end
  end
end
