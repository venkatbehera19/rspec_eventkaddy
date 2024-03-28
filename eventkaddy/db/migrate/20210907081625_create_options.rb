class CreateOptions < ActiveRecord::Migration[6.1]
  def change
    create_table :options do |t|
      t.integer :poll_id
      t.text :text
      t.timestamps
    end
  end
end
