class CreatePolls < ActiveRecord::Migration[6.1]
  def change
    create_table :polls do |t|
      t.integer :event_id
      t.string :title
      t.integer :response_limit, default: 1 # Defines number of times a user can respond to a poll
      t.integer :options_select_limit, default: 1 # Defines how many times an option of a poll can be selected
      t.boolean :allow_answer_change, default: false # Defines if user can change his/her answer   
      t.timestamps
    end
  end
end
