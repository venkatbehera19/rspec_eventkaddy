class AddPositionToCustomListItem < ActiveRecord::Migration[4.2]
  def change
  	add_column :custom_list_items, :position, :integer, :after => :content
  end
end
