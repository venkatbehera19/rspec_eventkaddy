class CreateIntegrationScripts < ActiveRecord::Migration[4.2]
  def change
    create_table :integration_scripts do |t|
      t.integer :event_id
      t.string  :button_label
      t.string  :script_name
      t.boolean :post_request
      t.boolean :job
      t.boolean :published
      t.timestamps
    end
  end
end
