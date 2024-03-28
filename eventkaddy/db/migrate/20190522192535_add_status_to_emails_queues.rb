class AddStatusToEmailsQueues < ActiveRecord::Migration[4.2]
  def change
    add_column :emails_queues, :status, :string, after: :sent
  end
end
