class AddFieldsToModeOfPayment < ActiveRecord::Migration[6.1]
  def change
    add_reference :mode_of_payments, :event
    add_column :mode_of_payments, :credentials, :text
    add_column :mode_of_payments, :key, :string
    add_column :mode_of_payments, :environment, :string
  end
end
