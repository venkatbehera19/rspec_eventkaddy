# frozen_string_literal: true

class AddProductPortalTabsToAttendeePortal < ActiveRecord::Migration[6.1]
  def up
    TabType.create(
      default_name: 'Product',
      controller_action: 'products',
      portal: "exhibitor"
    )
  end

  def down
    begin
      TabType.find_by(
        default_name: "Product",
        controller_action: 'products',
        portal: "exhibitor").delete
    rescue => exception
      raise ActiveRecord::IrreversibleMigration
    end
  end
end
