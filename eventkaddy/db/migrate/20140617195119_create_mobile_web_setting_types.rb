class CreateMobileWebSettingTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :mobile_web_setting_types do |t|
      t.string :name
      t.string :default

      t.timestamps
    end
  end
end
