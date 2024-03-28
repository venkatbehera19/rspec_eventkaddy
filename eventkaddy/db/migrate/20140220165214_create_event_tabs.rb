class CreateEventTabs < ActiveRecord::Migration[4.2]
  def change
    create_table :event_tabs do |t|
      t.integer :event_id
      t.boolean :welcome_tab_enabled
      t.string :welcome_tab_name
      t.boolean :contact_tab_enabled
      t.string :contact_tab_name
      t.boolean :travel_tab_enabled
      t.string :travel_tab_name
      t.boolean :sessions_tab_enabled
      t.string :sessions_tab_name
      t.boolean :payment_tab_enabled
      t.string :payment_tab_name
      t.boolean :messages_tab_enabled
      t.string :messages_tab_name
      t.boolean :pdf_tab_enabled
      t.string :pdf_tab_name

      t.timestamps
    end
  end
end
