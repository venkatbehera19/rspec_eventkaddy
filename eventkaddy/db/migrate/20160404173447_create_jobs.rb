class CreateJobs < ActiveRecord::Migration[4.2]
  def change
    create_table :jobs do |t|
      t.integer :event_id, :null => false
      t.string :name, :null => false
      t.string :status, :null => false
      t.integer :row
      t.integer :total_rows
      t.text :error_message

      t.timestamps
    end
    add_index :jobs, :event_id
  end
end
