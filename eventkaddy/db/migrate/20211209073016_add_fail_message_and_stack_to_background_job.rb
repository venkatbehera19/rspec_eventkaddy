class AddFailMessageAndStackToBackgroundJob < ActiveRecord::Migration[6.1]
  def change
    add_column :background_jobs, :fail_message, :string
    add_column :background_jobs, :error_stack, :text
  end
end
