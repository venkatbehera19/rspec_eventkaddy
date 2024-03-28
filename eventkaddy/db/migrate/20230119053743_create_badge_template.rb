class CreateBadgeTemplate < ActiveRecord::Migration[6.1]
  def change
    create_table :badge_templates do |t|
      t.string :name
      t.text   :json

      t.references :event
      t.timestamps
    end
  end
end
