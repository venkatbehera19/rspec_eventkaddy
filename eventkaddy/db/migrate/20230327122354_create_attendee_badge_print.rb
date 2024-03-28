class CreateAttendeeBadgePrint < ActiveRecord::Migration[6.1]
  def change
    create_table :attendee_badge_prints do |t|
      t.integer :attendee_id
      t.integer :badge_template_id
      t.integer :printed_by_id
      t.string  :printed_by_type
      t.integer :count, default: 0

      t.timestamps
    end
  end
end
