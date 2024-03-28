class CreateSpeakerFileTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :speaker_file_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
