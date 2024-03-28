# frozen_string_literal: true

class AddExhibitorPdfTabToExhibitorPortal < ActiveRecord::Migration[6.1]
  def up
    TabType.find_or_create_by(
      default_name: 'PDF Downloads',
      controller_action: 'download_pdf',
      portal: "exhibitor"
    )
  end

  def down
    begin
      TabType.find_by(
        default_name: 'PDF Downloads',
        controller_action: 'download_pdf',
        portal: "exhibitor"
      ).delete
    rescue => exception
      raise ActiveRecord::IrreversibleMigration
    end

  end
end
