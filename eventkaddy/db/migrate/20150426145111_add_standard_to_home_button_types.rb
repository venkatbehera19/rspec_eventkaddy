class AddStandardToHomeButtonTypes < ActiveRecord::Migration[4.2]
  def change
    add_column :home_button_types, :standard, :boolean, :after => :name
  end
end
