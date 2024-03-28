class ChangeTemplateToEmailTemplate < ActiveRecord::Migration[6.1]
  def change
    rename_table :templates, :email_templates
  end
end
