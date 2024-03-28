class AddStatusToOrder < ActiveRecord::Migration[6.1]
  def change
    add_column :orders, :registration_form_id, :integer
  end
end
