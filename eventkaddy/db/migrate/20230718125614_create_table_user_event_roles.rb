class CreateTableUserEventRoles < ActiveRecord::Migration[6.1]
  def change
    create_table :user_event_roles do |t|
      t.integer :users_event_id 
      t.integer :role_id
      t.timestamps
    end
  end
end
