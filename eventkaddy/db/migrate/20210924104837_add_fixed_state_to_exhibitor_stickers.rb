class AddFixedStateToExhibitorStickers < ActiveRecord::Migration[6.1]
  def change
    add_column :exhibitor_stickers, :fixed_state, :boolean, :default =>  true
  end
end
