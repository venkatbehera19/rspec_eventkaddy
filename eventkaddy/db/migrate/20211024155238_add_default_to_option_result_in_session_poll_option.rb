class AddDefaultToOptionResultInSessionPollOption < ActiveRecord::Migration[6.1]
  def change
    change_column_default :session_poll_options, :option_result, from: nil, to: 0
  end
end
