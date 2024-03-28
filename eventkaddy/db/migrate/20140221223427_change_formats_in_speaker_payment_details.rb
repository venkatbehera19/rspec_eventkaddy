class ChangeFormatsInSpeakerPaymentDetails < ActiveRecord::Migration[4.2]
  def self.up
   change_column :speaker_payment_details, :social_security_number, :string
   change_column :speaker_payment_details, :direct_bill_travel, :string
   change_column :speaker_payment_details, :direct_bill_housing, :string
   change_column :speaker_payment_details, :eligible_housing_nights, :string
   change_column :speaker_payment_details, :total_honorarium, :string
   change_column :speaker_payment_details, :total_per_diem, :string

  end

  def self.down
   change_column :speaker_payment_details, :social_security_number, :integer
   change_column :speaker_payment_details, :direct_bill_travel, :boolean
   change_column :speaker_payment_details, :direct_bill_housing, :boolean
   change_column :speaker_payment_details, :eligible_housing_nights, :integer
   change_column :speaker_payment_details, :total_honorarium, :decimal
   change_column :speaker_payment_details, :total_per_diem, :decimal
  end
end