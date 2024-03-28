class CreateTrackowners < ActiveRecord::Migration[4.2]
  def change
    create_table :trackowners do |t|
      t.integer :event_id
      t.integer :user_id
      t.string :honor_prefix
      t.string :first_name
      t.string :last_name
      t.string :honor_suffix
      t.string :email
      t.integer :photo_event_file_id
      t.boolean :unsubscribed
      t.string :token, :unique => true

      t.timestamps
    end
  end
end
