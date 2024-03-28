class AddTemplateIdToEmailsQueue < ActiveRecord::Migration[4.2]
  def change
    add_column :emails_queues, :template_id, :integer
  end
end
