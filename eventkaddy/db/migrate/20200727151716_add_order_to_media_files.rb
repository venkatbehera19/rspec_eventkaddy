class AddOrderToMediaFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :media_files, :position, :integer
  end
end
