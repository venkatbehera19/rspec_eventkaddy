class CreateScriptTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :script_types do |t|
      t.string :name
      t.string :file_location

      t.timestamps
    end
  end
end
