class ChangeItemTypeFieldInOrderItems < ActiveRecord::Migration[6.1]
  def change
    change_column :order_items, :item_type, :string
  end
end
