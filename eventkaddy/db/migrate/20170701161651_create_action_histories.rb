class CreateActionHistories < ActiveRecord::Migration[4.2]
  def change
    create_table :action_histories do |t|
      t.integer :event_id
      t.integer :action_history_type_id
      t.integer :user_id
      t.string :ip_address
      t.string :email
      t.string :action
      t.text :parameters

      t.timestamps
    end
  end
end
