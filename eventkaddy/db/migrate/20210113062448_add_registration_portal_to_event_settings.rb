class AddRegistrationPortalToEventSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :event_settings, :registration_portal, :boolean, :default => false
  end
end
