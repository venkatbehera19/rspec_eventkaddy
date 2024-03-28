class AddHideInAppToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :hide_in_app, :boolean, :after => :multi_event_status
  end
end
