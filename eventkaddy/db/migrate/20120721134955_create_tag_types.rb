class CreateTagTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :tag_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
