class AddtrackSubtrackToSessions < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :track_subtrack, :string
  end
end
