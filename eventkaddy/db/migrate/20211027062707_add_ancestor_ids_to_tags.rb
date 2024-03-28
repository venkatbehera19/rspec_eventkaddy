class AddAncestorIdsToTags < ActiveRecord::Migration[6.1]
  def change
    add_column :tags, :ancestor_ids, :string
  end
end
