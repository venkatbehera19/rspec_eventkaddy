class CreateInitialEventFileTypeRecords < ActiveRecord::Migration[6.1]
  def change
    EventFileType.find_or_create_by(name: 'exhibitor_registration_banner')
    EventFileType.find_or_create_by(name: 'exhibitor_registration_header_bg_img')
    EventFileType.find_or_create_by(name: 'exhibitor_registration_header_content')
    EventFileType.find_or_create_by(name: 'exhibitor_registration_portal_image')
  end
end
