class CreateSurveySections < ActiveRecord::Migration[4.2]
  def change
    create_table :survey_sections do |t|
      t.belongs_to :event
      t.belongs_to :survey
      t.integer :order
      t.string :heading
      t.text :subheading

      t.timestamps
    end
    add_index :survey_sections, :event_id
    add_index :survey_sections, :survey_id
  end
end
