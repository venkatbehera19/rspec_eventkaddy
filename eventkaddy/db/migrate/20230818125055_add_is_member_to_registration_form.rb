class AddIsMemberToRegistrationForm < ActiveRecord::Migration[6.1]
  def change
    add_column :registration_forms, :is_member, :boolean, :default => false
  end
end
