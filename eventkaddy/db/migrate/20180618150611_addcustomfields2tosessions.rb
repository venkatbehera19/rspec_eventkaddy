class Addcustomfields2tosessions < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :custom_fields_2, :text
  end
end
