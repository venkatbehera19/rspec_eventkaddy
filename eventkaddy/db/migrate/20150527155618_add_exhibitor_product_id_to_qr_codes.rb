class AddExhibitorProductIdToQrCodes < ActiveRecord::Migration[4.2]
  def change
    add_column :qr_codes, :exhibitor_product_id, :integer, :after => :event_file_id
  end
end
