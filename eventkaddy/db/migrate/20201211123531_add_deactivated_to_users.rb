class AddDeactivatedToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :deactivated, :boolean, :default => false
  end
end
