class AddOrderToAnswers < ActiveRecord::Migration[4.2]
  def change
    add_column :answers, :order, :integer, :after => :question_id
  end
end
