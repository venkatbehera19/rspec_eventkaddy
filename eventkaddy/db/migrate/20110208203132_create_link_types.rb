class CreateLinkTypes < ActiveRecord::Migration[4.2]
  def self.up
    create_table :link_types do |t|
      t.string :link_type

      t.timestamps
    end
  end

  def self.down
    drop_table :link_types
  end
end
