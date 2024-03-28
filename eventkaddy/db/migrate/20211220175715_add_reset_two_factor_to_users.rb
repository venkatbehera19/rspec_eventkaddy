class AddResetTwoFactorToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :reset_two_factor_token, :string, unique: true
  end
end
