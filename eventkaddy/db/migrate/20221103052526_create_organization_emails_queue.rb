class CreateOrganizationEmailsQueue < ActiveRecord::Migration[6.1]
  def change
    create_table :organization_emails_queues do |t|
      t.string   :email
      t.string   :status
      t.integer  :email_type_id
      t.integer  :organization_email_template_id
      t.boolean  :sent
      t.boolean  :deliver_later
      t.boolean  :attach_calendar_invite
      t.datetime :active_time #for deliver_later time
      t.datetime :calendar_invite_start
      t.datetime :calendar_invite_end
      t.string   :timezone


      t.references :organization
      t.references :user
      t.timestamps
    end
  end
end
