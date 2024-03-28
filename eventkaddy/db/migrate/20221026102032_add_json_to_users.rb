class AddJsonToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :json, :text
  end
end
