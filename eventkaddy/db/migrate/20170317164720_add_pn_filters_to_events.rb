class AddPnFiltersToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :pn_filters, :text, :after => :master_url
  end
end

