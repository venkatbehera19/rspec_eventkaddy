class AddUnpublishedToSessions < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :unpublished, :boolean, :after => :event_id
  end
end
