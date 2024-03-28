class AddExhibitorStaffIdToEmailsQueues < ActiveRecord::Migration[4.2]
  def change
    add_column :emails_queues, :exhibitor_staff_id, :integer
  end
end
