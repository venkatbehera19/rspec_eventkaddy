class AddLearningObjectiveToSessions < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :learning_objective, :text
  end
end
