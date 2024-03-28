class AddOrderToHints < ActiveRecord::Migration[4.2]
  def change
    add_column :hints, :order, :integer, :after => :question_id
  end
end
