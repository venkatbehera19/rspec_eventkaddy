class AddWelcomeChatToExhibitors < ActiveRecord::Migration[4.2]
  def change
    add_column :exhibitors, :welcome_chat, :text
  end
end
