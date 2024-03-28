# frozen_string_literal: true

class AddExhibitorPortalFileToEventFileType < ActiveRecord::Migration[6.1]
  def up
    EventFileType.find_or_create_by( name: 'exhibitor_portal_file' )
  end

  def down
    begin
      EventFileType.find_by( name: 'exhibitor_portal_file' ).delete
    rescue => exception
      raise ActiveRecord::IrreversibleMigration
    end

  end
end
