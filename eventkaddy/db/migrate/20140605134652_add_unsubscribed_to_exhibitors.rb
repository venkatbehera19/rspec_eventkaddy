class AddUnsubscribedToExhibitors < ActiveRecord::Migration[4.2]
  def change
    add_column :exhibitors, :unsubscribed, :boolean
  end
end
