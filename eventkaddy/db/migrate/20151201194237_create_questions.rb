class CreateQuestions < ActiveRecord::Migration[4.2]
  def change
    create_table :questions do |t|
      t.belongs_to :event
      t.belongs_to :survey
      t.belongs_to :question_type
      t.text :question

      t.timestamps
    end
    add_index :questions, :event_id
    add_index :questions, :survey_id
    add_index :questions, :question_type_id
  end
end
