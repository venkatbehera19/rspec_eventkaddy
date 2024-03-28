# frozen_string_literal: true

class SpeakerEventFileTypeToEventFileType < ActiveRecord::Migration[6.1]
  def up
    speaker_event_file_types = ['speaker_registration_banner', 'registration_portal_bg_img', 'speaker_registration_header_bg_img', 'speaker_registration_header_content']

    speaker_event_file_types.each do |speaker_event_file_type|
      EventFileType.find_or_create_by(name: speaker_event_file_type)
    end
  end

  def down
    begin
      speaker_event_file_types = ['speaker_registration_banner', 'registration_portal_bg_img', 'speaker_registration_header_bg_img', 'speaker_registration_header_content']

      speaker_event_file_types.each do |speaker_event_file_type|
        EventFileType.find_by(name: speaker_event_file_type).delete
      end

    rescue => exception
      raise ActiveRecord::IrreversibleMigration
    end
  end
end
