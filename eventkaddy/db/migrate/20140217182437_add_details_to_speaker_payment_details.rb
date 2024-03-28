class AddDetailsToSpeakerPaymentDetails < ActiveRecord::Migration[4.2]
  def change
    add_column :speaker_payment_details, :social_security_number, :integer
    add_column :speaker_payment_details, :pay_to_line1, :string
    add_column :speaker_payment_details, :pay_to_line2, :string
    add_column :speaker_payment_details, :direct_bill_travel, :boolean
    add_column :speaker_payment_details, :direct_bill_housing, :boolean
    add_column :speaker_payment_details, :eligible_housing_nights, :integer
    add_column :speaker_payment_details, :payment_type, :string
    add_column :speaker_payment_details, :eligible_payment_rate, :string
    add_column :speaker_payment_details, :total_honorarium, :decimal
    add_column :speaker_payment_details, :total_per_diem, :decimal
  end
end
