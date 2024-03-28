class AddTypeToPnHashToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :type_to_pn_hash, :text, after: :pn_filters
  end
end
