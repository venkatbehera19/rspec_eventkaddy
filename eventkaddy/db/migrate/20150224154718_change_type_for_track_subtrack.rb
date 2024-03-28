class ChangeTypeForTrackSubtrack < ActiveRecord::Migration[4.2]
  def self.up
    change_table :sessions do |t|
      t.change :track_subtrack, :text
    end
  end
  def self.down
    change_table :sessions do |t|
      t.change :track_subtrack, :string
    end
  end
end
