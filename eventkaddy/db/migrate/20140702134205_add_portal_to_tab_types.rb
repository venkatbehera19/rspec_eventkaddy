class AddPortalToTabTypes < ActiveRecord::Migration[4.2]
  def change
    add_column :tab_types, :portal, :string, :after => :controller_action
  end
end
