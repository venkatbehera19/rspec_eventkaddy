class CreateUsersRoles < ActiveRecord::Migration[4.2]
  def self.up
    create_table :users_roles do |t|
	  t.references :role, :user
      t.timestamps
    end
  end

  def self.down
    drop_table :users_roles
  end
end
