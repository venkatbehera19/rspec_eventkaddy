class AddPhotoFilenameToExhibitor < ActiveRecord::Migration[6.1]
  def change
    add_column :exhibitors, :photo_filename, :string
  end
end
