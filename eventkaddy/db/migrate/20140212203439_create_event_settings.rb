class CreateEventSettings < ActiveRecord::Migration[4.2]
  def change
    create_table :event_settings do |t|
      t.integer :event_id
      t.integer :portal_logo_event_file_id
      t.string :travel_and_lodging_form
      t.boolean :hide_cv
      t.boolean :hide_bio
      t.boolean :sessions_editable
      t.text :av_requirements_content
      t.text :welcome_screen_content
      t.text :support_email_address

      t.timestamps
    end
  end
end
