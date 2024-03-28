class AddDefaultValueToFields < ActiveRecord::Migration[6.1]
  def change
    change_column_default(:sessions, :unpublished, from: nil, to: false)
    change_column_default(:sessions, :premium_access, from: nil, to: false)
    change_column_default(:sessions, :on_demand, from: nil, to: false)
    change_column_default(:sessions_speakers, :unpublished, from: nil, to: false)
  end
end
