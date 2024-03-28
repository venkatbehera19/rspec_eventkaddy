class AddPnFiltersToNotifications < ActiveRecord::Migration[4.2]
  def change
    add_column :notifications, :pn_filters, :text
  end
end
