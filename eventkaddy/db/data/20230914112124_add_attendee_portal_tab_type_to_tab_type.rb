# frozen_string_literal: true

class AddAttendeePortalTabTypeToTabType < ActiveRecord::Migration[6.1]
  def up
    TabType.find_or_create_by(
      default_name: "Welcome",
      controller_action: "landing",
      portal: "attendee_portal"
    )
    TabType.find_or_create_by(
      default_name: "Profile",
      controller_action: "profile",
      portal: "attendee_portal"
    )
    TabType.find_or_create_by(
      default_name: "Products",
      controller_action: "product",
      portal: "attendee_portal"
    )
    TabType.find_or_create_by(
      default_name: "My Orders",
      controller_action: "my_orders",
      portal: "attendee_portal"
    )
  end

  def down
    begin
      TabType.find_by(
        default_name: "Welcome",
        controller_action: "landing",
        portal: "attendee_portal"
      ).delete
      TabType.find_by(
        default_name: "Profile",
        controller_action: "profile",
        portal: "attendee_portal"
      ).delete
      TabType.find_by(
        default_name: "Products",
        controller_action: "product",
        portal: "attendee_portal"
      ).delete
      TabType.find_by(
        default_name: "My Orders",
        controller_action: "my_orders",
        portal: "attendee_portal"
      ).delete
    rescue => exception
      raise ActiveRecord::IrreversibleMigration
    end
  end
end
