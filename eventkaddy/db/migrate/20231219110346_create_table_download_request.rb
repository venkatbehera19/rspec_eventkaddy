class CreateTableDownloadRequest < ActiveRecord::Migration[6.1]
  def change
    create_table :download_requests do |t|
      t.integer :event_id
      t.integer :user_id
      t.string :request_type
      t.string :status
      t.string :job_id
      t.text   :error_message

      t.timestamps
    end
  end
end
