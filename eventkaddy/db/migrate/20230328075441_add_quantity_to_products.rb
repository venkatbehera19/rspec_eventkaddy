class AddQuantityToProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :start_date, :datetime
    add_column :products, :end_date,   :datetime
    add_column :products, :quantity,   :integer
  end
end
