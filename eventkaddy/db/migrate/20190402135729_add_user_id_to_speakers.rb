class AddUserIdToSpeakers < ActiveRecord::Migration[4.2]
  def change
    add_column :speakers, :user_id, :integer, :after => :email
  end
end
