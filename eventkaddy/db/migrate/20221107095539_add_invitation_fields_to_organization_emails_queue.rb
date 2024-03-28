class AddInvitationFieldsToOrganizationEmailsQueue < ActiveRecord::Migration[6.1]
  def change
    add_column :organization_emails_queues, :invitation_fields, :text
  end
end
