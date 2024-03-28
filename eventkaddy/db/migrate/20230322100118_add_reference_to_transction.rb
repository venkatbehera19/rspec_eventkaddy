class AddReferenceToTransction < ActiveRecord::Migration[6.1]
  def change
    add_reference :transactions, :registration_form_carts, foreign_key: true
  end
end
