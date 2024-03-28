class CreateSurveySessions < ActiveRecord::Migration[4.2]
  def change
    create_table :survey_sessions do |t|
      t.integer :event_id
      t.integer :survey_id
      t.integer :session_id

      t.timestamps
    end
    add_index :survey_sessions, :survey_id
    add_index :survey_sessions, :session_id
  end
end
