class CreateTableWebhooks < ActiveRecord::Migration[6.1]
  def change
    create_table :webhooks do |t|
      t.string  :event_id 
      t.string  :event_type
      t.string  :email
      t.string  :transaction_id
      t.string  :status
      t.integer :amount
      t.timestamps
    end
  end
end
