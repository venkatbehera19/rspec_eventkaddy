class AddpublishpdftoSessions < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :publish_pdf, :boolean, after: :session_file_urls
  end
end
