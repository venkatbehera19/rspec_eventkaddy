class CreateComments < ActiveRecord::Migration[4.2]
  def change
    create_table :comments do |t|
      t.string :title
      t.text :content
      t.integer :session_id
      t.integer :attendee_id

      t.timestamps
    end
  end
end
