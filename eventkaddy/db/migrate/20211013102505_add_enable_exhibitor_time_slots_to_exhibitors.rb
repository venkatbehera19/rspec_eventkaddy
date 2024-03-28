class AddEnableExhibitorTimeSlotsToExhibitors < ActiveRecord::Migration[6.1]
  def change
    add_column :exhibitors, :enable_exhibitor_time_slots, :boolean, default: false
  end
end
