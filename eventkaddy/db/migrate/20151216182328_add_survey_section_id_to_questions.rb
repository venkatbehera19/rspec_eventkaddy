class AddSurveySectionIdToQuestions < ActiveRecord::Migration[4.2]
  def change
    add_column :questions, :survey_section_id, :integer, :after => :event_id
    add_index :questions, :survey_section_id
  end
end
