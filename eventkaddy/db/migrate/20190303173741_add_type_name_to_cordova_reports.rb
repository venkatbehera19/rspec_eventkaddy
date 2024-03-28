class AddTypeNameToCordovaReports < ActiveRecord::Migration[4.2]
  def change
    add_column :cordova_reports, :type_name, :string, :after => :id
  end
end
