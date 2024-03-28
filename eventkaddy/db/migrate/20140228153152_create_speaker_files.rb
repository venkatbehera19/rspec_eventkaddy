class CreateSpeakerFiles < ActiveRecord::Migration[4.2]
  def change
    create_table :speaker_files do |t|
      t.integer :event_id
      t.integer :event_file_id
      t.integer :speaker_id
      t.integer :speaker_file_type
      t.string :title
      t.string :description

      t.timestamps
    end
  end
end
