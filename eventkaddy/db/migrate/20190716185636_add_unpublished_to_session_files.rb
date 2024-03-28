class AddUnpublishedToSessionFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :session_files, :unpublished, :boolean, :after => :description
  end
end
