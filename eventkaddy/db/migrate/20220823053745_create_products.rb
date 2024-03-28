class CreateProducts < ActiveRecord::Migration[6.1]
  def change
    create_table :products do |t|
      t.string :iid, :null => false
      t.text :description
      t.decimal :price, precision: 5, scale: 2
      t.boolean :deleted, :default => false
      t.datetime :deleted_at
      t.integer  :deleted_by
      t.integer :image_event_file_id
      t.index   :iid
      t.references :event
      t.references :product_categories

      t.timestamps

    end
  end
end
