class AddAccountIdToModeOfPayment < ActiveRecord::Migration[6.1]
  def change
    add_column :mode_of_payments, :merchant_account_id, :string
    add_column :mode_of_payments, :merchant_partner_name, :string
  end
end
