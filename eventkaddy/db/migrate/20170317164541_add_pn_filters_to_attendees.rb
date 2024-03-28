class AddPnFiltersToAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :pn_filters, :text, :after => :custom_filter_3
  end
end

