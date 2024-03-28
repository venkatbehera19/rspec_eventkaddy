class CreateTableSessionKeyword < ActiveRecord::Migration[6.1]
  def change
    create_table :session_keywords do |t|
      t.string :name 
      t.integer :session_id
      t.integer :event_id
      t.integer :speaker_id
      t.timestamps
    end
  end
end
