class AddIsPostertoSessions < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :is_poster, :boolean
  end
end
