class AddOthersToKeywordSession < ActiveRecord::Migration[6.1]
  def change
    add_column :session_keywords, :other_keyword, :boolean, :default => false
  end
end
