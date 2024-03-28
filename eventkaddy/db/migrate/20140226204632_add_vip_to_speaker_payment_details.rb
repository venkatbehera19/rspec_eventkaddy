class AddVipToSpeakerPaymentDetails < ActiveRecord::Migration[4.2]
  def change	
  	add_column :speaker_payment_details, :vip_code, :string
  end
end
