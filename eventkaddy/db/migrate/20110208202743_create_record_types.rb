class CreateRecordTypes < ActiveRecord::Migration[4.2]
  def self.up
    create_table :record_types do |t|
      t.string :record_type

      t.timestamps
    end
  end

  def self.down
    drop_table :record_types
  end
end
