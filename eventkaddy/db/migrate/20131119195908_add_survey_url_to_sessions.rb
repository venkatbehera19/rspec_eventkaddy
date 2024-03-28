class AddSurveyUrlToSessions < ActiveRecord::Migration[4.2]
  def change
  	add_column :sessions, :survey_url, :text
  end
end
