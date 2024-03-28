class ChangeSpeakerTypeColumn < ActiveRecord::Migration[4.2]
  def change
  	remove_column :speakers, :speaker_type
  	add_column :speakers, :speaker_type_id, :integer 
  end

end
