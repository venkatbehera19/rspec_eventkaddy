class AddPdfEventFileToHomeButton < ActiveRecord::Migration[6.1]
  def change
    add_column :home_buttons, :pdf_event_file_id, :integer
  end
end
