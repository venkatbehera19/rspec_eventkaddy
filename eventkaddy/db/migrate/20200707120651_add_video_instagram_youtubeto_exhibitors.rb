class AddVideoInstagramYoutubetoExhibitors < ActiveRecord::Migration[4.2]
  def change
	add_column :exhibitors, :url_video, :string
	add_column :exhibitors, :url_instagram, :string
	add_column :exhibitors, :url_youtube, :string
  end

end
