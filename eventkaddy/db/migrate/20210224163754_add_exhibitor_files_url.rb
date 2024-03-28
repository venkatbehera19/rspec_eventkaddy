class AddExhibitorFilesUrl < ActiveRecord::Migration[4.2]
  def change
      add_column :exhibitors, :exhibitor_files_url, :text, after: :custom_fields
  end
end
