class AddSoldOuttoSessions < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :sold_out, :boolean
  end
end
