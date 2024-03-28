class CreateRecordComments < ActiveRecord::Migration[4.2]
  def self.up
    create_table :record_comments do |t|
      t.text :comment
      t.integer :user_id
      t.integer :record_id
      t.timestamps
    end
  end

  def self.down
    drop_table :record_comments
  end
end
