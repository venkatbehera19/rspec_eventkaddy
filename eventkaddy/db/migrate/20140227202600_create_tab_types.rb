class CreateTabTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :tab_types do |t|
      t.string :default_name
      t.string :controller_action

      t.timestamps
    end
  end
end
