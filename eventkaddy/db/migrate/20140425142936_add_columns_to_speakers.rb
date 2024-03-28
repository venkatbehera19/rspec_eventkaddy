class AddColumnsToSpeakers < ActiveRecord::Migration[4.2]
  def change
    add_column :speakers, :twitter_url, :string
    add_column :speakers, :facebook_url, :string
    add_column :speakers, :linked_in, :string
  end
end
