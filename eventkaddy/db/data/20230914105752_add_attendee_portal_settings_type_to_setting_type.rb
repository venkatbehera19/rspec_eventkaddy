# frozen_string_literal: true

class AddAttendeePortalSettingsTypeToSettingType < ActiveRecord::Migration[6.1]
  def up
    SettingType.find_or_create_by(name: "attendee_portal_settings")
  end

  def down
    begin
      SettingType.find_by(name: "attendee_portal_settings").delete
    rescue => exception
      raise ActiveRecord::IrreversibleMigration
    end
  end
end
