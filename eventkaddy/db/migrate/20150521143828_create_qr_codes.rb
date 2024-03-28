class CreateQrCodes < ActiveRecord::Migration[4.2]
  def change
    create_table :qr_codes do |t|
      t.integer :event_id
      t.integer :event_file_id

      t.timestamps
    end
  end
end
