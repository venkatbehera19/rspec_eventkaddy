class CreateAppGames < ActiveRecord::Migration[4.2]
  def change
    create_table :app_games do |t|
      t.integer :event_id
      t.string :name
      t.string :description
      t.boolean :active

      t.timestamps
    end
  end
end
