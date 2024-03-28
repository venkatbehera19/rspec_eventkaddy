# frozen_string_literal: true

class AddExhibitorPdfUploadToEventFileType < ActiveRecord::Migration[6.1]
  def up
    ['exhibitor_pdf_upload', 'exhibitor_pdf_no_sign'].each do |event_file_type|
      EventFileType.find_or_create_by( name: event_file_type )
    end
  end

  def down
    begin
      ['exhibitor_pdf_upload', 'exhibitor_pdf_no_sign'].each do |event_file_type|
        EventFileType.find_by( name: event_file_type ).delete
      end
    rescue => exception
      raise ActiveRecord::IrreversibleMigration
    end

  end
end
