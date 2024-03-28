class AddCeFieldsToSurveys < ActiveRecord::Migration[4.2]
  def change
    add_column :surveys, :post_action, :string, after: :ends
    add_column :surveys, :submit_success_message, :string, after: :post_action
    add_column :surveys, :submit_failure_message, :string, after: :submit_success_message
  end
end
