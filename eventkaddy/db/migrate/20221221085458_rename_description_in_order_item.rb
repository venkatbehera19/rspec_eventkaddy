class RenameDescriptionInOrderItem < ActiveRecord::Migration[6.1]
  def change
    rename_column :order_items, :description, :name
  end
end
