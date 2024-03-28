class CreateExhibitorFileTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :exhibitor_file_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
