# class ChangeSessionIdToBeIntegerInSessionsAttendees < ActiveRecord::Migration
#   puts 'ChangeSessionIdToBeInteger commented out (on purpose).'
  # commented out, because I am concerned that some programs, like the cordova
  # app or the mobile website, may be relying on this column to be a string.
  # But I want to keep this here just because it's good to know it's possible
  # def up
  #   change_column :sessions_attendees, :session_id, :integer
  # end

  # def down
  #   change_column :sessions_attendees, :session_id, :string
  # end
# end
