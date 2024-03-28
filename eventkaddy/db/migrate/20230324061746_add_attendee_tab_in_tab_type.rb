class AddAttendeeTabInTabType < ActiveRecord::Migration[6.1]
  def change
    TabType.create(
      default_name: 'Attendee Payment',
      controller_action: 'registration_setting',
      portal: 'attendee'
    )
  end
end
