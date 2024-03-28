class AddChatColumnsToExhibitors < ActiveRecord::Migration[4.2]
  def change
    add_column :exhibitors, :enable_chat, :boolean, :default => false
    add_column :exhibitors, :unavailable_chat, :text
  end
end
