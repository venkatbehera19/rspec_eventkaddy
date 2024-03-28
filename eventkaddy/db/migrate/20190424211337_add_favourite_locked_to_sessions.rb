class AddFavouriteLockedToSessions < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :favourite_locked, :boolean, after: :published
  end
end
