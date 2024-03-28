class CreateTagsSessions < ActiveRecord::Migration[4.2]
  def change
    create_table :tags_sessions do |t|
      t.integer :tag_id
      t.integer :session_id

      t.timestamps
    end
  end
end
