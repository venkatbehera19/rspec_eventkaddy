class AddMailerFieldToCeCertificates < ActiveRecord::Migration[4.2]
  def change
    add_column :ce_certificates, :mailer, :text
  end
end
