class AddutcOffsetToEvents < ActiveRecord::Migration[4.2]

  def change
    add_column :events, :utc_offset, :string
  end
  
  

end
