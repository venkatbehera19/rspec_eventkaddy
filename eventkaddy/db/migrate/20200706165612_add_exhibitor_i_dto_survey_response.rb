class AddExhibitorIDtoSurveyResponse < ActiveRecord::Migration[4.2]
  def change
	add_column :survey_responses, :exhibitor_id, :int
  end

end
