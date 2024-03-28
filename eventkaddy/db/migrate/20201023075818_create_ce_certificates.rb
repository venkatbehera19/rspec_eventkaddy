class CreateCeCertificates < ActiveRecord::Migration[4.2]
  def change
    create_table :ce_certificates do |t|
      t.string :name
      t.integer :event_id
      t.integer :event_file_id
      t.integer :ce_certificate_type_id
      t.text :json

      t.timestamps
    end
    add_index :ce_certificates, :event_id
    add_index :ce_certificates, :event_file_id
    add_index :ce_certificates, :ce_certificate_type_id
  end
end
