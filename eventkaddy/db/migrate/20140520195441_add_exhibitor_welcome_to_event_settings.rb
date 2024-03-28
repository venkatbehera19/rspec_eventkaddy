class AddExhibitorWelcomeToEventSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :event_settings, :exhibitor_welcome, :string
  end
end
