# frozen_string_literal: true

class AddFormFileTypesToEventFileType < ActiveRecord::Migration[6.1]
  def up
    ["android_app_icon_img","ios_app_icon_img","android_landscape_splash_screen_img","android_portrait_splash_screen_img","ios_splash_screen_img"].each do |app_img_type|
      EventFileType.create(name: app_img_type)
    end
  end

  def down
    begin
      ["android_app_icon_img","ios_app_icon_img","android_landscape_splash_screen_img","android_portrait_splash_screen_img","ios_splash_screen_img"].each do |app_img_type|
        EventFileType.find_by(name: app_img_type).delete
      end
    rescue
      raise ActiveRecord::IrreversibleMigration
    end
  end
end
