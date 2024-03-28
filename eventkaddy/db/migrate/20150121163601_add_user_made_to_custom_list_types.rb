class AddUserMadeToCustomListTypes < ActiveRecord::Migration[4.2]
  def change
    add_column :custom_list_types, :user_made, :boolean, :after => :name
  end
end
