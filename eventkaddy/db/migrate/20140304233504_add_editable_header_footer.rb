class AddEditableHeaderFooter < ActiveRecord::Migration[4.2]
  def change
  
  	add_column :tabs, :header_text, :text
  	add_column :tabs, :body_text, :text
  	add_column :tabs, :footer_text, :text
  end

  
end
