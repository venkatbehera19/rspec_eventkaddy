class AddStatusToRegistrationForm < ActiveRecord::Migration[6.1]
  def change
    add_column :registration_forms, :status, :string
  end
end
