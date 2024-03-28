class CreateTags < ActiveRecord::Migration[4.2]
  def change
    create_table :tags do |t|
      t.string :name
      t.integer :level
      t.boolean :leaf
      t.integer :parent_id
      t.integer :event_id
      t.integer :tag_type_id

      t.timestamps
    end
  end
end
