class CreateAnswerHandlers < ActiveRecord::Migration[6.1]
  def change
    create_table :answer_handlers do |t|
      t.string :handler

      t.timestamps
    end
  end
end
