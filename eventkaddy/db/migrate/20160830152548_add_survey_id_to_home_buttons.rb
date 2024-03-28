class AddSurveyIdToHomeButtons < ActiveRecord::Migration[4.2]
  def change
    add_column :home_buttons, :survey_id, :integer, :after => :position
  end
end
