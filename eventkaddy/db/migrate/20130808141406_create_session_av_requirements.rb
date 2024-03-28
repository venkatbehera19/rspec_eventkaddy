class CreateSessionAvRequirements < ActiveRecord::Migration[4.2]
  def change
    create_table :session_av_requirements do |t|
      t.integer :event_id
      t.integer :session_id
      t.integer :speaker_id
      t.integer :av_list_item_id
      t.text :additional_notes

      t.timestamps
    end
  end
end
