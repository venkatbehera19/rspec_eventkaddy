class CreateAppSubmissionForms < ActiveRecord::Migration[6.1]
  def change
    create_table :app_submission_forms do |t|
      t.string :app_name
      t.string :subtitle
      t.text :description
      t.text :keywords, array: true
      t.references(:event, null: false, type: :int,foreign_key: true)
      t.references :app_form_type, null: false, foreign_key: true

      t.timestamps
    end
  end
end
