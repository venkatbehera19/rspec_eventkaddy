class AddRecordsForMemberModule < ActiveRecord::Migration[6.1]
  def change
    EventFileType.find_or_create_by(name: "member_page_banner")
    EmailType.find_or_create_by(name: "organization_email")
    TemplateType.find_or_create_by(name: "member_subscribe_email_template")
    TemplateType.find_or_create_by(name: "member_unsubscribe_email_template")
    SettingType.find_or_create_by(name: "organization_members_settings")
  end
end