class ChangeOptionToOptionTextInSessionPollOption < ActiveRecord::Migration[6.1]
  def change
    rename_column :session_poll_options, :option, :option_text
  end
end
