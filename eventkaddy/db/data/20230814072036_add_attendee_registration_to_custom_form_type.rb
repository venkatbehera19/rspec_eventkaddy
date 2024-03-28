# frozen_string_literal: true

class AddAttendeeRegistrationToCustomFormType < ActiveRecord::Migration[6.1]
  def up
    CustomFormType.find_or_create_by(
      name: 'Attendee Registration', 
      iid: 'attendee_registration'
    )
  end

  def down
    begin
      CustomFormType.find_by(
        name: 'Attendee Registration', 
        iid: 'attendee_registration'
      ).delete
    rescue => exception
      raise ActiveRecord::IrreversibleMigration
    end
  end
end
