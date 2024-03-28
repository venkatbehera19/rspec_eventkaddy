class AddEventServerToEvent < ActiveRecord::Migration[4.2]
  def change
      add_column :events, :event_server, :string, :after => :diy_user_pass
  end
end
