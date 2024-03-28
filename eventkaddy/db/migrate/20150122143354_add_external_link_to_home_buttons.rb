class AddExternalLinkToHomeButtons < ActiveRecord::Migration[4.2]
  def change
    add_column :home_buttons, :external_link, :string
  end
end
