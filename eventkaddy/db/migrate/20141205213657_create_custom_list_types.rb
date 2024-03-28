class CreateCustomListTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :custom_list_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
