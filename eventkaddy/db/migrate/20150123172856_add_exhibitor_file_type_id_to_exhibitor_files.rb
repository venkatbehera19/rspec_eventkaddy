class AddExhibitorFileTypeIdToExhibitorFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :exhibitor_files, :exhibitor_file_type_id, :integer
  end
end
