class AddOriginalDocumentIdToSpeakerFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :speaker_files, :original_document_id, :integer
  end
end
