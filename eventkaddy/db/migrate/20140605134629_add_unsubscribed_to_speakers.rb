class AddUnsubscribedToSpeakers < ActiveRecord::Migration[4.2]
  def change
    add_column :speakers, :unsubscribed, :boolean
  end
end
