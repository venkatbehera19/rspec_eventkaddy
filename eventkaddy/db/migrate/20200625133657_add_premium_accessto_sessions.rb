class AddPremiumAccesstoSessions < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :premium_access, :boolean 
  end
end
