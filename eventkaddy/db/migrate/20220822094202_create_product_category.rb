class CreateProductCategory < ActiveRecord::Migration[6.1]
  def change
    create_table :product_categories do |t|
      t.string :iid 
      t.text :name
      t.index :iid
      t.references :event

      t.timestamps
    end
  end
end
