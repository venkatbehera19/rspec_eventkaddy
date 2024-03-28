class CreateTabs < ActiveRecord::Migration[4.2]
  def change
    create_table :tabs do |t|
      t.integer :event_id
      t.integer :tab_type_id
      t.string :name
      t.boolean :enabled
      t.integer :order

      t.timestamps
    end
  end
end
