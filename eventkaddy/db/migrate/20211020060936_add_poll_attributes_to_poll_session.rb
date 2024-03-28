class AddPollAttributesToPollSession < ActiveRecord::Migration[6.1]
  def change
    add_column :poll_sessions, :title, :string
    add_column :poll_sessions, :response_limit, :integer, default: 1
    add_column :poll_sessions, :options_select_limit, :integer, default: 1
    add_column :poll_sessions, :allow_answer_change, :boolean, default: false
    add_column :poll_sessions, :timeout_time, :integer, default: 30
  end
end
