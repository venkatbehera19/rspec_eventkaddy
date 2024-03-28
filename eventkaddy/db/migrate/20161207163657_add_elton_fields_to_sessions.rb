class AddEltonFieldsToSessions < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :promotion, :string
    add_column :sessions, :keyword, :string
  end
end
