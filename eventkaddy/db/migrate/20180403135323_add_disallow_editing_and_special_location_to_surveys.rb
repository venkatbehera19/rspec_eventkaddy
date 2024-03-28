class AddDisallowEditingAndSpecialLocationToSurveys < ActiveRecord::Migration[4.2]
  def change
    add_column :surveys, :disallow_editing, :boolean, after: :submit_failure_message
    add_column :surveys, :special_location, :string, after: :disallow_editing
  end
end
