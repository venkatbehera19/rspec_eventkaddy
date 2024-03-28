class RenameRegistrationFormCartToRenameRegistraionFormCarts < ActiveRecord::Migration[6.1]
  def change
    rename_table :registration_form_cart, :registration_form_carts
  end
end
