class CreateBoothSizeTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :booth_size_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
