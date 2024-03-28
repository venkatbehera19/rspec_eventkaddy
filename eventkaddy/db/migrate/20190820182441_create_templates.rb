class CreateTemplates < ActiveRecord::Migration[4.2]
  def change
    create_table :templates do |t|
      t.integer :event_id
      t.string :name
      t.text :content
      t.integer :template_type_id

      t.timestamps
    end
  end
end
