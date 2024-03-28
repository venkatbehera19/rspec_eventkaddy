class AddTitleToSpeakers < ActiveRecord::Migration[4.2]
  def change
    add_column :speakers, :title, :string, :after => :honor_suffix
  end
end
