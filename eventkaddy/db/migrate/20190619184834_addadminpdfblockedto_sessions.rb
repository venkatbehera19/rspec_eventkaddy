class AddadminpdfblockedtoSessions < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :admin_pdf_blocked, :boolean, after: :publish_pdf
  end
end
