class AddDomainstoEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :chat_url, :string
    add_column :events, :reporting_url, :string
    add_column :events, :cms_url, :string
  end
end
