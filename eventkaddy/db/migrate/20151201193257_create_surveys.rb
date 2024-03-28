class CreateSurveys < ActiveRecord::Migration[4.2]
  def change
    create_table :surveys do |t|
      t.integer :event_id
      t.string :title
      t.text :description
      t.datetime :begins
      t.datetime :ends

      t.timestamps
    end
  end
end
