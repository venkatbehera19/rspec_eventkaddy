class AddShowOnHomeFeedToHomeButtons < ActiveRecord::Migration[6.1]
  def change
    add_column :home_buttons, :show_on_home_feed, :boolean, :after => :hide_on_mobile_site, :default => false
  end
end
