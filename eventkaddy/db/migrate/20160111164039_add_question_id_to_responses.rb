class AddQuestionIdToResponses < ActiveRecord::Migration[4.2]
  def change
    add_column :responses, :question_id, :integer, :after => :survey_response_id
    add_index :responses, :question_id
  end
end
