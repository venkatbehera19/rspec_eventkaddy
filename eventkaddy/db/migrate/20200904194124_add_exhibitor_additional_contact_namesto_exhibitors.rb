class AddExhibitorAdditionalContactNamestoExhibitors < ActiveRecord::Migration[4.2]
  def change
	add_column :exhibitors, :contact_name_two, :string, after: :url_youtube
  end
end
