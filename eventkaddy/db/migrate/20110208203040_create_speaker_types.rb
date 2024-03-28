class CreateSpeakerTypes < ActiveRecord::Migration[4.2]
  def self.up
    create_table :speaker_types do |t|
      t.string :speaker_type

      t.timestamps
    end
  end

  def self.down
    drop_table :speaker_types
  end
end
