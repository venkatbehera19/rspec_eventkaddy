class AddOriginalDocumentIdToExhibitorFiles < ActiveRecord::Migration[6.1]
  def change
    add_column :exhibitor_files, :original_document_id, :integer
  end
end
