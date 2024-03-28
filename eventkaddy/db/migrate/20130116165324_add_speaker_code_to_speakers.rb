class AddSpeakerCodeToSpeakers < ActiveRecord::Migration[4.2]
  def change
  	add_column :speakers, :speaker_code, :string
  end
end
