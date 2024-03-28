class AddVirtualPortalUrlToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :virtual_portal_url, :string
  end
end
