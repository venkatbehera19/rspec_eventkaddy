class RegistrationFormCartItems < ActiveRecord::Migration[6.1]
  def change
    create_table :registration_form_cart_items do |t|
      t.integer :item_id 
      t.string  :item_type
      t.integer :quantity, :default => 1

      t.references :registration_form_cart
      t.timestamps
    end
  end
end
