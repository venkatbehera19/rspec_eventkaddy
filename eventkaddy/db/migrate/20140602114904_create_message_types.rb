class CreateMessageTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :message_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
