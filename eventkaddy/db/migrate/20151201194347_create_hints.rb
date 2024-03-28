class CreateHints < ActiveRecord::Migration[4.2]
  def change
    create_table :hints do |t|
      t.belongs_to :event
      t.belongs_to :question
      t.text :hint

      t.timestamps
    end
    add_index :hints, :event_id
    add_index :hints, :question_id
  end
end
