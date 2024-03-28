class CreateHomeButtonEntryTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :home_button_entry_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
