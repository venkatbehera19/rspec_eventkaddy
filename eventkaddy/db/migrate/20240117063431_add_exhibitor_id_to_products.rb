class AddExhibitorIdToProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :exhibitor_id, :integer
  end
end
