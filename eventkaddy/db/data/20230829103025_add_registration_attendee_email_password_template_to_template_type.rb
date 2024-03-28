# frozen_string_literal: true

class AddRegistrationAttendeeEmailPasswordTemplateToTemplateType < ActiveRecord::Migration[6.1]
  def up
    ['registration_attendee_email_password_template', 'registration_attendee_confirmation_email_template'].each do |email_template|
      TemplateType.find_or_create_by( name: email_template )
    end
  end

  def down
    begin
      ['registration_attendee_email_password_template', 'registration_attendee_confirmation_email_template'].each do |email_template|
        TemplateType.find_by(name: email_template).delete  
      end
    rescue => exception
      raise ActiveRecord::IrreversibleMigration
    end
  end
end
