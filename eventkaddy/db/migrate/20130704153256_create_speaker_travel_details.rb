class CreateSpeakerTravelDetails < ActiveRecord::Migration[4.2]
  def change
    create_table :speaker_travel_details do |t|
      t.integer :speaker_id
      t.date :approved_arrival_date
      t.date :approved_departure_date
      t.date :actual_arrival_date
      t.date :actual_departure_date
      t.string :hotel_name
      t.string :hotel_confirmation_number
      t.string :hotel_cost
      t.string :hotel_reimbursement
      t.string :airfare_cost
      t.string :airfare_reimbursement
      t.string :mileage
      t.text :comments

      t.timestamps
    end
  end
end
