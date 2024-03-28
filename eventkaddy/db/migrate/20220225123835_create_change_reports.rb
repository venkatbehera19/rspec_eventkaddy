class CreateChangeReports < ActiveRecord::Migration[6.1]
  def change
    create_table :change_reports do |t|
      t.string :upload_action
      t.references :user
      t.references :event, null: false
      t.references :event_file, null: false

      t.timestamps
    end
  end
end
