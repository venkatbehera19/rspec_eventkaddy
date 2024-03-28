class CreateUsersOrganizations < ActiveRecord::Migration[4.2]
  def self.up
    create_table :users_organizations do |t|
      t.integer :user_id
      t.integer :org_id

      t.timestamps
    end
  end

  def self.down
    drop_table :users_organizations
  end
end
