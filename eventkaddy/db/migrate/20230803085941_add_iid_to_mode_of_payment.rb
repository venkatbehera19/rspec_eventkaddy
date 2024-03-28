class AddIidToModeOfPayment < ActiveRecord::Migration[6.1]
  def change
    add_column :mode_of_payments, :iid, :string
    add_index :mode_of_payments, :iid
  end
end
