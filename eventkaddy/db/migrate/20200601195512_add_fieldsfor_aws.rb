class AddFieldsforAws < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :video_file_location, :string
  end
end
