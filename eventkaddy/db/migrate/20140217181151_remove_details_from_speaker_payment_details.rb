class RemoveDetailsFromSpeakerPaymentDetails < ActiveRecord::Migration[4.2]
  def up
    remove_column :speaker_payment_details, :fielda
    remove_column :speaker_payment_details, :fieldb
    remove_column :speaker_payment_details, :fieldc
    remove_column :speaker_payment_details, :fieldd
    remove_column :speaker_payment_details, :fielde
    remove_column :speaker_payment_details, :fieldf
    remove_column :speaker_payment_details, :fieldg
    remove_column :speaker_payment_details, :fieldh
  end

  def down
    add_column :speaker_payment_details, :fieldh, :string
    add_column :speaker_payment_details, :fieldg, :string
    add_column :speaker_payment_details, :fieldf, :string
    add_column :speaker_payment_details, :fielde, :string
    add_column :speaker_payment_details, :fieldd, :string
    add_column :speaker_payment_details, :fieldc, :string
    add_column :speaker_payment_details, :fieldb, :string
    add_column :speaker_payment_details, :fielda, :string
  end
end
