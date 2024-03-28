class AddDeletedToEventFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :event_files, :deleted, :boolean, :default=>false
  end
end
