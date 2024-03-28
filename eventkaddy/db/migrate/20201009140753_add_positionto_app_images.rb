class AddPositiontoAppImages < ActiveRecord::Migration[4.2]
  def change
    add_column :app_images, :position, :integer
  end
end
