class AddUnpublishedToSessionSpeakers < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions_speakers, :unpublished, :boolean, :after => :speaker_id
  end
end
