class AddFieldsToSessions < ActiveRecord::Migration[6.1]
  def change
    add_column :sessions, :fields, :text
  end
end
