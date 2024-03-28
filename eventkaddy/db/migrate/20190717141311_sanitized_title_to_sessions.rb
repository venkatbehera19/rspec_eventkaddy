class SanitizedTitleToSessions < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :sanitized_title, :string
  end
end
