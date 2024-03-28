class CreateOrganizationEmailTemplate < ActiveRecord::Migration[6.1]
  def change
    create_table :organization_email_templates do |t|
      t.string :email_subject
      t.text   :content

      t.references :organization
      t.references :template_type
      t.timestamps
    end
  end
end
