class FixColumnNameInSpeakerFiles < ActiveRecord::Migration[4.2]
  def change
    rename_column :speaker_files, :speaker_file_type, :speaker_file_type_id
  end
end