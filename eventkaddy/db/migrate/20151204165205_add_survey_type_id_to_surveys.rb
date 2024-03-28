class AddSurveyTypeIdToSurveys < ActiveRecord::Migration[4.2]
  def change
    add_column :surveys, :survey_type_id, :integer, :after => :event_id
    add_index :surveys, :survey_type_id
  end
end
