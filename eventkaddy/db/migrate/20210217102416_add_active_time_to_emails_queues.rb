class AddActiveTimeToEmailsQueues < ActiveRecord::Migration[4.2]
  def change
    add_column :emails_queues, :active_time, :datetime
    add_column :emails_queues, :deliver_later, :boolean
  end
end
