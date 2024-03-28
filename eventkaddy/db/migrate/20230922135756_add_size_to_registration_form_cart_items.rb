class AddSizeToRegistrationFormCartItems < ActiveRecord::Migration[6.1]
  def change
    add_column :registration_form_cart_items, :size, :string
  end
end
