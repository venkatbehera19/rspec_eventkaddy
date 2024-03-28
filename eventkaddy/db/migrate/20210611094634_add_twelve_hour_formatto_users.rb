class AddTwelveHourFormattoUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :twelve_hour_format, :boolean
  end
end
