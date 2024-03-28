class AddTagSetsHashToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :tag_sets_hash, :text, after: :type_to_pn_hash
  end
end
