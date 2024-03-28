class RegistrationFormCart < ActiveRecord::Migration[6.1]
  def change
    create_table :registration_form_cart do |t| 
      t.references :registration_form
      t.string :status
      t.timestamps
    end
  end
end
