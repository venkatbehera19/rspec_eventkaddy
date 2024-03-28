class AddBadgeNameToAttendeeAndRegistrationForm < ActiveRecord::Migration[6.1]
  def change
    add_column :attendees, :badge_name, :string
    add_column :registration_forms, :badge_name, :string
  end
end
