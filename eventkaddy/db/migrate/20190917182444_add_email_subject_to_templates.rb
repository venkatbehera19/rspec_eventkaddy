class AddEmailSubjectToTemplates < ActiveRecord::Migration[4.2]
  def change
    add_column :templates, :email_subject, :string, after: :name
  end
end
