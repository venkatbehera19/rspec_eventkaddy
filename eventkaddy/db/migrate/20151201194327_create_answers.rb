class CreateAnswers < ActiveRecord::Migration[4.2]
  def change
    create_table :answers do |t|
      t.belongs_to :event
      t.belongs_to :question
      t.text :answer
      t.boolean :correct

      t.timestamps
    end
    add_index :answers, :event_id
    add_index :answers, :question_id
  end
end
