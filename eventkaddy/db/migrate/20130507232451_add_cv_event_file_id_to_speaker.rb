class AddCvEventFileIdToSpeaker < ActiveRecord::Migration[4.2]
  def change

  	add_column :speakers, :cv_event_file_id, :integer
  end
end
