class AddLockFieldsToLocationMapping < ActiveRecord::Migration[6.1]
  def change
    add_column :location_mappings, :locked_by, :integer
    add_column :location_mappings, :locked_at, :datetime
  end
end
