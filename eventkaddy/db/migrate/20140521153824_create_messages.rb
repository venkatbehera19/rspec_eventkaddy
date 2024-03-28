class CreateMessages < ActiveRecord::Migration[4.2]
  def change
    create_table :messages do |t|
      t.integer :event_id
      t.string :title
      t.string :content
      t.datetime :local_time
      t.datetime :active_time
      t.string :status
      t.boolean :mail
      t.integer :message_type

      t.timestamps
    end
    add_index :messages, :event_id
  end
end
