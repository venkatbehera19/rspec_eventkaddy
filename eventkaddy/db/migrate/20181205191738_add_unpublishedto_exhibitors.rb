class AddUnpublishedtoExhibitors < ActiveRecord::Migration[4.2]
  def change
    add_column :exhibitors, :unpublished, :boolean, after: :event_id
  end
end
