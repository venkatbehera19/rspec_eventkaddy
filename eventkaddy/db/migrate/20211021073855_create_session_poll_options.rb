class CreateSessionPollOptions < ActiveRecord::Migration[6.1]
  def change
    create_table :session_poll_options do |t|
      t.references :poll_session, null: false, foreign_key: true
      t.string :option
      t.integer :option_result
      t.integer :activate_history

      t.timestamps
    end
  end
end
