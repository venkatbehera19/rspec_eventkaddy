class AddAvailabilityNotesToSpeakers < ActiveRecord::Migration[4.2]
  def change
    add_column :speakers, :availability_notes, :text, :after => :notes
  end
end
