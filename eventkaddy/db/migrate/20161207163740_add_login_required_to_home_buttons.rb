class AddLoginRequiredToHomeButtons < ActiveRecord::Migration[4.2]
  def change
    add_column :home_buttons, :login_required, :boolean, :after => :enabled
  end
end
