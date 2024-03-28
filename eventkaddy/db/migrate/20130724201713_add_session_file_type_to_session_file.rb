class AddSessionFileTypeToSessionFile < ActiveRecord::Migration[4.2]
  def change
    	add_column :session_files, :session_file_type_id, :integer
  end
end
