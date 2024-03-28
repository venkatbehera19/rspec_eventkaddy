class CreateEventSponsorLevelTypes < ActiveRecord::Migration[6.1]
  def change
    create_table :event_sponsor_level_types do |t|
      t.integer :event_id
      t.integer :sponsor_level_type_id
      t.integer :rank

      t.timestamps
    end
  end
end
