class AddSpeakerIdToSpeakerPaymentDetails < ActiveRecord::Migration[4.2]
  def change
    add_column :speaker_payment_details, :speaker_id, :integer
  end
end
