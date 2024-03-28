class AddTimezoneToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :timezone, :string
    add_column :events, :calendar_json, :text
  end
end
