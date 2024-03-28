# frozen_string_literal: true

class AddAttendeePaymentTabType < ActiveRecord::Migration[6.1]
  def up
    tab_type = TabType.find_by(
      controller_action: "registration_setting",
      portal: "attendee"
    )
    if tab_type.present?
      tab_type.delete
    end
    ['Attendee Registration', 'Attendee Product', 'Attendee Cart', 'Attendee Payment'].each do |default_name|
      TabType.find_or_create_by(
        default_name: default_name,
        controller_action: "registration_setting",
        portal: "attendee"
      )
    end
  end

  def down
    begin
      ['Attendee Registration', 'Attendee Cart', 'Attendee Product', 'Attendee Payment'].each do |default_name|
        TabType.find_by(
          default_name: default_name,
          controller_action: "registration_setting",
          portal: "attendee"
        ).delete
      end
    rescue => exception
      raise ActiveRecord::IrreversibleMigration
    end
  end
end
