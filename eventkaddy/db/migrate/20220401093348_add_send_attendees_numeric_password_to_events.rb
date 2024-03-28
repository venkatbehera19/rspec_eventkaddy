class AddSendAttendeesNumericPasswordToEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :send_attendees_numeric_password, :boolean, {default: true}
  end
end
