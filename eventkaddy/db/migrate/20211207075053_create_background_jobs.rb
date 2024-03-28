class CreateBackgroundJobs < ActiveRecord::Migration[6.1]
  def change
    create_table :background_jobs do |t|
      t.integer :external_job_id
      t.string :purpose
      t.string :status
      t.integer :entity_id
      t.string :entity_type
      t.index :entity_type
      t.index :entity_id

      t.timestamps
    end
  end
end
