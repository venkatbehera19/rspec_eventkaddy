class AddTitleToCustomListItem < ActiveRecord::Migration[4.2]
  def change
  	add_column :custom_list_items, :title, :text, :after => :custom_list_id
  end
end
