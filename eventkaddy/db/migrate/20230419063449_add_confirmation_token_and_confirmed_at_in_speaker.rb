class AddConfirmationTokenAndConfirmedAtInSpeaker < ActiveRecord::Migration[6.1]
  def change
    add_column :speakers, :confirmation_token, :string
    add_column :speakers, :confirmed_at, :datetime
  end
end
