class CreateCeCertificateTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :ce_certificate_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
