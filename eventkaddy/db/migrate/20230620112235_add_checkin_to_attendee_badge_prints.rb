class AddCheckinToAttendeeBadgePrints < ActiveRecord::Migration[6.1]
  def change
    add_column :attendee_badge_prints, :check_in, :boolean, :default => false
  end
end
