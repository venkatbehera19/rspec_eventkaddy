class CreateCategoryExclusions < ActiveRecord::Migration[6.1]
  def change
    create_table :category_exclusions do |t|
      t.integer :category_id
      t.integer :excluded_category_id

      t.timestamps
    end
  end
end
