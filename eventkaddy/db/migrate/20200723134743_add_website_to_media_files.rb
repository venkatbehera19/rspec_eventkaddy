class AddWebsiteToMediaFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :media_files, :website, :text
  end
end
