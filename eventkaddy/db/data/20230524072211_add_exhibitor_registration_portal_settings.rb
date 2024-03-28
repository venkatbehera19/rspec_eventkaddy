# frozen_string_literal: true

class AddExhibitorRegistrationPortalSettings < ActiveRecord::Migration[6.1]
  def up
    setting_type = SettingType.where(name: 'exhibitor_registration_portal_settings').first
    if !setting_type.present?
      SettingType.create(name: 'exhibitor_registration_portal_settings')
    end
  end

  def down
    begin
      SettingType.find_by(name: 'exhibitor_registration_portal_settings').delete
    rescue => exception
      raise ActiveRecord::IrreversibleMigration
    end
  end
end
