class AddDefaultToActivateHistory < ActiveRecord::Migration[6.1]
  def change
    change_column_default :poll_sessions, :activate_history, from: nil, to: 0
  end
end
