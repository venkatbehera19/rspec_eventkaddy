class AddLinkToVideoPortalImages < ActiveRecord::Migration[4.2]
  def change
    add_column :video_portal_images, :link, :string, :after => :name
  end
end
