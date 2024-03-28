class CreateSpeakerPaymentDetails < ActiveRecord::Migration[4.2]
  def change
    create_table :speaker_payment_details do |t|
      t.string :fielda
      t.string :fieldb
      t.string :fieldc
      t.string :fieldd
      t.string :fielde
      t.string :fieldf
      t.string :fieldg
      t.string :fieldh

      t.timestamps
    end
  end
end
