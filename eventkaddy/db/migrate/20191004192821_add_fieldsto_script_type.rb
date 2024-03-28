class AddFieldstoScriptType < ActiveRecord::Migration[4.2]
  def change
    add_column :script_types, :url, :string, after: :name
    add_column :script_types, :post_request, :boolean, after: :url
    add_column :script_types, :job, :boolean, after: :post_request
    rename_column :script_types, :file_location, :file_name
  end
end
