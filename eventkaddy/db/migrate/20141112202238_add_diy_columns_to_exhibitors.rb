class AddDiyColumnsToExhibitors < ActiveRecord::Migration[4.2]
  def change
    add_column :exhibitors, :exhibitor_code, :string
    add_index :exhibitors, :exhibitor_code
    add_column :exhibitors, :diy_uploaded_location_name, :string
    add_column :exhibitors, :diy_uploaded_tagsets, :text
  end
end
