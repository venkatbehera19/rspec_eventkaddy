class AddTokenToSpeakers < ActiveRecord::Migration[4.2]
  def change
    add_column :speakers, :token, :string, :unique => true
  end
end
