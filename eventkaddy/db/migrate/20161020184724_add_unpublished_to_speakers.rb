class AddUnpublishedToSpeakers < ActiveRecord::Migration[4.2]
  def change
    add_column :speakers, :unpublished, :boolean, :after => :event_id
  end
end
