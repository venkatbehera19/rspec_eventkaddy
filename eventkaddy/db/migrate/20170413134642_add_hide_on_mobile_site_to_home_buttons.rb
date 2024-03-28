class AddHideOnMobileSiteToHomeButtons < ActiveRecord::Migration[4.2]
  def change
    add_column :home_buttons, :hide_on_mobile_site, :boolean, :after => :enabled
  end
end
