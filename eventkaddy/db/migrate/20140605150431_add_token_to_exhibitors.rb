class AddTokenToExhibitors < ActiveRecord::Migration[4.2]
  def change
    add_column :exhibitors, :token, :string, :unique => true
  end
end
