class AddOrderToTags < ActiveRecord::Migration[4.2]
  def change
    add_column :tags, :order, :string, :after => :meta_data
  end
end
