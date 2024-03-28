# frozen_string_literal: true

class SpeakerRegistrationSettingsToSettingType < ActiveRecord::Migration[6.1]
  def up
    SettingType.find_or_create_by(name: "speaker_registration_settings")
  end

  def down
    begin
      SettingType.find_by(name: "speaker_registration_settings").delete
    rescue => exception
      raise ActiveRecord::IrreversibleMigration
    end
  end
end
