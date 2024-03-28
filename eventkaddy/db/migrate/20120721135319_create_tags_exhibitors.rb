class CreateTagsExhibitors < ActiveRecord::Migration[4.2]
  def change
    create_table :tags_exhibitors do |t|
      t.integer :tag_id
      t.integer :exhibitor_id

      t.timestamps
    end
  end
end
