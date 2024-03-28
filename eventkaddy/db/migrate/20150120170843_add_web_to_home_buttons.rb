class AddWebToHomeButtons < ActiveRecord::Migration[4.2]
  def change
    add_column :home_buttons, :web, :boolean
  end
end
