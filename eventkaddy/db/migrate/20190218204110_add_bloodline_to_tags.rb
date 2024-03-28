class AddBloodlineToTags < ActiveRecord::Migration[4.2]
  def change
    add_column :tags, :bloodline, :string, :after => :parent_id
  end
end
