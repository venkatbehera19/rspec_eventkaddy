class AddHomeButtonEntryTypeToHomeButtonEntry < ActiveRecord::Migration[4.2]
  def change
  	add_column :home_button_entries, :home_button_entry_type_id, :integer

  end
end
