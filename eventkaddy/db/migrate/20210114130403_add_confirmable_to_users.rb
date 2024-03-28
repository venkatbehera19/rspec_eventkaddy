class AddConfirmableToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :confirmation_token, :string, index: true, unique: true
    add_column :users, :confirmed_at, :datetime
  end
end
