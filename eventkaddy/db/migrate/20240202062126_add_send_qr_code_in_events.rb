class AddSendQrCodeInEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :send_qr_code, :boolean, :default => false
  end
end
