class AddPathToDownloadRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :download_requests, :path, :text
  end
end
