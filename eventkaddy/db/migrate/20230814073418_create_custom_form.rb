class CreateCustomForm < ActiveRecord::Migration[6.1]
  def change
    create_table :custom_forms do |t|
      t.string  :name
      t.integer :custom_form_type_id
      t.text    :json
      t.integer :event_id
      t.timestamps
    end
  end
end
