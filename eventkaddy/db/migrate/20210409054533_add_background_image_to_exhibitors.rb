class AddBackgroundImageToExhibitors < ActiveRecord::Migration[4.2]
  def change
    add_column :exhibitors, :background_image, :integer
  end
end
