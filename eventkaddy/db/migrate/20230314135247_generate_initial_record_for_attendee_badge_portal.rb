class GenerateInitialRecordForAttendeeBadgePortal < ActiveRecord::Migration[6.1]
  def change
    SettingType.find_or_create_by(name: 'attendee_badge_portal_settings')
    EventFileType.find_or_create_by(name: 'attendee_badge_portal_banner')
    EventFileType.find_or_create_by(name: 'attendee_badge_portal_bg_banner')
  end
end
