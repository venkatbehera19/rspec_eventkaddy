class CreateUnsubscribedEmails < ActiveRecord::Migration[4.2]
  def change
    create_table :unsubscribed_emails do |t|
      t.string :email

      t.timestamps
    end
  end
end
