class CreateHiddenNotificationTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :hidden_notification_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
