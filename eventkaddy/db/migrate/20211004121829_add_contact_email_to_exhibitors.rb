class AddContactEmailToExhibitors < ActiveRecord::Migration[6.1]
  def change
    add_column :exhibitors, :contact_email, :string unless column_exists?(:exhibitors, :contact_email)
  end
end
