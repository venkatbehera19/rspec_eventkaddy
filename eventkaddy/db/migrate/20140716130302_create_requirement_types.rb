class CreateRequirementTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :requirement_types do |t|
      t.string :name
      t.string :requirement_for

      t.timestamps
    end
  end
end
