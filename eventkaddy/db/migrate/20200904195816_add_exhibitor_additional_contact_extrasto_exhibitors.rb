class AddExhibitorAdditionalContactExtrastoExhibitors < ActiveRecord::Migration[4.2]
  def change
	add_column :exhibitors, :contact_title_two, :string, after: :contact_name_two
        add_column :exhibitors, :contact_email_two, :string, after: :contact_title_two
        add_column :exhibitors, :contact_mobile_two, :string, after: :contact_email_two
  end
end
