class CreateResponses < ActiveRecord::Migration[4.2]
  def change
    create_table :responses do |t|
      t.belongs_to :event
      t.belongs_to :survey_response
      t.belongs_to :answer
      t.text :response

      t.timestamps
    end
    add_index :responses, :event_id
    add_index :responses, :survey_response_id
    add_index :responses, :answer_id
  end
end
