class AddAnswerHandlerRefToAnswers < ActiveRecord::Migration[6.1]
  def change
    add_reference :answers, :answer_handler, null: true
  end
end
