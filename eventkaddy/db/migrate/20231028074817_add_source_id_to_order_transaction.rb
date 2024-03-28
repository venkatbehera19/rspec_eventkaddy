class AddSourceIdToOrderTransaction < ActiveRecord::Migration[6.1]
  def change
    add_column :order_transactions, :source_id, :string
  end
end
