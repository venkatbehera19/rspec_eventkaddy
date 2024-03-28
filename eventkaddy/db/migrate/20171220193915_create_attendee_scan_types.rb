class CreateAttendeeScanTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :attendee_scan_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
