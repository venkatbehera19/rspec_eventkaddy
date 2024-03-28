class AddOthersToTagsSession < ActiveRecord::Migration[6.1]
  def change
    add_column :tags_sessions, :other_tag, :boolean, :default =>  false
    #Ex:- :default =>''
  end
end
