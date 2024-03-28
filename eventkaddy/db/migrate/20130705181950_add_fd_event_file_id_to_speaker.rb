class AddFdEventFileIdToSpeaker < ActiveRecord::Migration[4.2]
  def change
  
  	add_column :speakers, :fd_event_file_id, :integer

  end
end
