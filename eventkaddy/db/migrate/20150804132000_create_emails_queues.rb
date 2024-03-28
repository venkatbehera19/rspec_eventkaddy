class CreateEmailsQueues < ActiveRecord::Migration[4.2]
  def change
    create_table :emails_queues do |t|
      t.integer :event_id
      t.integer :email_type_id
      t.boolean :sent
      t.string :email
      t.string :message
      t.integer :attendee_id
      t.integer :speaker_id
      t.integer :exhibitor_id
      t.integer :user_id
      t.integer :trackowner_id

      t.timestamps
    end
  end
end
