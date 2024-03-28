class AddResultDisplayTypeToPolls < ActiveRecord::Migration[6.1]
  def change
    add_column :polls, :result_display_type, :string, :default => "VERTICAL_CHART"
  end
end
