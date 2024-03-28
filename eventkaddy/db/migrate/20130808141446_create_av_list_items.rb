class CreateAvListItems < ActiveRecord::Migration[4.2]
  def change
    create_table :av_list_items do |t|
      t.string :name

      t.timestamps
    end
  end
end
