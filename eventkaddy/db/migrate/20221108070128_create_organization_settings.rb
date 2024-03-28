class CreateOrganizationSettings < ActiveRecord::Migration[6.1]
  def change
    create_table :organization_settings do |t|
      t.text :json

      t.references :organization
      t.references :setting_type
      t.timestamps
    end
  end
end
