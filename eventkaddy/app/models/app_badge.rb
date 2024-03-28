class AppBadge < ApplicationRecord

	include ListItem
	extend ListItem

  # attr_accessible :app_game_id, :image_event_file_id, :alt_image_url, :description, :details, :position, :event_id, :min_points_to_complete, :name, :min_badge_tasks_to_complete

  belongs_to :event
  belongs_to :app_game

  belongs_to :event_file, :foreign_key => 'image_event_file_id', :dependent => :destroy

  has_many :app_badge_tasks, :dependent => :destroy

  has_many :attendees_app_badges
  has_many :attendees, :through => :attendees_app_badges

  def self.detailed_badge_info id
    app_badge = find id
    if app_badge.event_file
      if app_badge.event_file.cloud_storage_type_id.blank?
        image = app_badge.event_file.path
      else
        image = app_badge.event_file.return_authenticated_url()['url']
      end
    else
      image = "No image."
    end
    app_badge.event_file && app_badge.event_file.cloud_storage_type_id

    {
      name:                        app_badge.name,
      description:                 app_badge.description,
      image:                       image,
      details:                     app_badge.details,
      min_badge_tasks_to_complete: app_badge.min_badge_tasks_to_complete,
      min_points_to_complete:      app_badge.min_points_to_complete,
      game_url:                    "/app_games/#{app_badge.app_game_id}",
      edit_url:                    "/app_badges/#{id}/edit",
      new_task_url:                "/app_badge_tasks/new?app_badge_id=#{app_badge.id}",
      tasks:                       app_badge.app_badge_tasks.order(:position).map {|t| 
                                     t_image = t.event_file && t.event_file.path || "No image."
                                     {
                                       position:   t.position,
                                       image:      t_image,
                                       name:       t.name,
                                       type:       t.app_badge_task_type.name,
                                       tasks_url:  "/app_badge_tasks/#{t.id}",
                                       edit_url:   "/app_badge_tasks/#{t.id}/edit",
                                       delete_url: "/app_badge_tasks/#{t.id}"
                                     } 
                                   }
    }
  end

  def update_image image_file
    event_file_type_id = EventFileType.where(name:'app_badge_image').first.id
    file_extension     = File.extname image_file.original_filename

    event_file = image_event_file_id ? EventFile.find(image_event_file_id)
                               : EventFile.new(event_id:event_id,event_file_type_id:event_file_type_id)
    cloud_storage_type_id = Event.find(event_id).cloud_storage_type_id
    unless cloud_storage_type_id.blank?
      cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
    end
    UploadEventFileImage.new(
      event_file:              event_file,
      image:                   image_file,
      target_path:             Rails.root.join('public', 'event_data', event_id.to_s, 'app_badge_images').to_path,
      new_filename:            "#{name.downcase.gsub(/[^a-zA-Z_0-9]/, '_')}#{Time.now.strftime('%Y%m%d%H%M%S')}#{file_extension}",
      event_file_owner:        self,
      event_file_assoc_column: :image_event_file_id,
      new_height:              300,
      new_width:               300,
      cloud_storage_type:      cloud_storage_type
    ).call
  end

  def stats
    result = AttendeesAppBadge.find_by_sql(["
      SELECT *, 
             app_badges.name AS name,
             SUM(app_badge_points_collected) AS total_points_collected,
             AVG(num_app_badge_tasks_completed) AS average_tasks_completed,
             COUNT( CASE WHEN attendees_app_badges.complete=1 THEN 1 END) AS completed_count,
             COUNT( CASE WHEN attendees_app_badges.complete=0 THEN 1 END) AS partially_completed_count,
             COUNT( CASE WHEN attendees_app_badges.prize_redeemed=1 THEN 1 END) AS redeemed_count
      FROM attendees_app_badges
      JOIN app_badges ON attendees_app_badges.app_badge_id=app_badges.id
      WHERE app_badge_id=? AND app_badge_points_collected IS NOT NULL
      GROUP BY app_badge_id
      ORDER BY app_badges.name", id]).first
    return no_stats unless result
    {
      name:                        result.name,
      min_points_to_complete:      result.min_points_to_complete,
      min_badge_tasks_to_complete: result.min_badge_tasks_to_complete,
      total_points_collected:      result.total_points_collected,
      average_tasks_completed:     result.average_tasks_completed.to_i,
      partially_completed_count:   result.partially_completed_count,
      completed_count:             result.completed_count,
      redeemed_count:              result.redeemed_count
    }
  end

  def no_stats
    {
      name:                        name,
      min_points_to_complete:      min_points_to_complete,
      min_badge_tasks_to_complete: min_badge_tasks_to_complete,
      total_points_collected:      0,
      average_tasks_completed:     0,
      partially_completed_count:   0,
      completed_count:             0,
      redeemed_count:              0
    }
  end
end

