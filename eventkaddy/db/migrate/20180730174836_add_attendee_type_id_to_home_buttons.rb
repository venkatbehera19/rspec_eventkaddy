class AddAttendeeTypeIdToHomeButtons < ActiveRecord::Migration[4.2]
  def change
    add_column :home_buttons, :attendee_type_id, :integer, after: :survey_id
  end
end
