class AddMasterUrlToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :master_url, :string
  end
end
