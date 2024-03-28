class AddMetaDataToTag < ActiveRecord::Migration[4.2]
  def change
  	add_column :tags, :meta_data, :text
  end
end
