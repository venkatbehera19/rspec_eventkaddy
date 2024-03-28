class CreateSurveyCeCertificates < ActiveRecord::Migration[6.1]
  def change
    create_table :survey_ce_certificates do |t|
      t.integer :event_id
      t.integer :survey_id
      t.integer :ce_certificate_id

      t.timestamps
    end
  end
end
