class AddOrderToQuestions < ActiveRecord::Migration[4.2]
  def change
    add_column :questions, :order, :integer, :after => :question_type_id
  end
end
