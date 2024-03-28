class UpdateColumnKeywodsInSession < ActiveRecord::Migration[6.1]
  def change
    change_column :sessions, :keyword, :text
  end
end
