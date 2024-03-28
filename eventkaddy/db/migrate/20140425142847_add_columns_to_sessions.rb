class AddColumnsToSessions < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :poll_url, :string
  end
end
