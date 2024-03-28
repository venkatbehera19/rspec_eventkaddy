class AddEltonFieldsToMobileWebSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :mobile_web_settings, :position, :integer, :after => :content
    add_column :mobile_web_settings, :device_type_id, :integer, :after => :content
  end
end
