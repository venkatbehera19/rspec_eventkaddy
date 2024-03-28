class AddApiKeyToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :api_key, :string
  end
end
