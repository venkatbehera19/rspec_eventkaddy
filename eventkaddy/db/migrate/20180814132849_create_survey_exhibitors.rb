class CreateSurveyExhibitors < ActiveRecord::Migration[4.2]
  def change
    create_table :survey_exhibitors do |t|
      t.integer :event_id
      t.integer :survey_id
      t.integer :exhibitor_id

      t.timestamps
    end
  end
end
