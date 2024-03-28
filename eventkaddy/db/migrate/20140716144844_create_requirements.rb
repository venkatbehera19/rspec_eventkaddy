class CreateRequirements < ActiveRecord::Migration[4.2]
  def change
    create_table :requirements do |t|
      t.integer :event_id
      t.integer :requirement_type_id
      t.boolean :required

      t.timestamps
    end
  end
end
