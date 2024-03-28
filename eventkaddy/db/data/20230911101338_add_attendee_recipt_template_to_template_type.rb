# frozen_string_literal: true

class AddAttendeeReciptTemplateToTemplateType < ActiveRecord::Migration[6.1]
  def up
    TemplateType.find_or_create_by( name: "registration_attendee_receipt_template" )
  end

  def down
    begin
      TemplateType.find_by(name: "registration_attendee_receipt_template").delete  
    rescue => exception
      raise ActiveRecord::IrreversibleMigration
    end
  end
  
end
