class ChangeAttendeeBiographyToText < ActiveRecord::Migration[4.2]
  def up
      change_column :attendees, :biography, :text
  end
  def down
      change_column :attendees, :biography, :string
  end
end
