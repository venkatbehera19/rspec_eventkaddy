class AppBadgeTask < ApplicationRecord

	include ListItem
	extend ListItem

  # attr_accessible :app_game_id, :image_event_file_id, :alt_image_url, :app_badge_task_type_id, :app_badge_id, :description, :details, :position, :event_id, :name, :points_per_action, :points_to_complete, :max_points_allotable, :scavenger_hunt_id, :scavenger_hunt_item_id, :survey_id

  belongs_to :app_game, :optional => true
  belongs_to :app_badge
  belongs_to :app_badge_task_type
  belongs_to :event
  belongs_to :scavenger_hunt_item, :optional => true
  belongs_to :survey, :optional => true

  belongs_to :event_file, :foreign_key => 'image_event_file_id', :optional => true

  has_many :attendees_app_badge_tasks
  has_many :attendees, :through => :attendees_app_badge_tasks

  # TODO: scavenger hunts and session survey badge types need special attention

  def self.detailed_badge_task_info id
    app_badge_task      = find id
    if app_badge_task.event_file
      if app_badge_task.event_file.cloud_storage_type_id.blank?
        image = app_badge_task.event_file.path
      else
        image = app_badge_task.event_file.return_authenticated_url()['url']
      end
    else
      image = "No image."
    end
    badge_type          = app_badge_task.app_badge_task_type.name
    scavenger_hunt_item = app_badge_task.scavenger_hunt_item && app_badge_task.scavenger_hunt_item.name
    survey_title = app_badge_task.survey && app_badge_task.survey.title
    {
      name:                 app_badge_task.name,
      position:             app_badge_task.position,
      type:                 badge_type,
      scavenger_hunt_item:  scavenger_hunt_item,
      survey_title:         survey_title,
      description:          app_badge_task.description,
      image:                image,
      details:              app_badge_task.details,
      points_per_action:    app_badge_task.points_per_action,
      points_to_complete:   app_badge_task.points_to_complete,
      max_points_allotable: app_badge_task.max_points_allotable,
      badge_url:             "/app_badges/#{app_badge_task.app_badge_id}",
      edit_url:             "/app_badge_tasks/#{id}/edit",
      max_points_per_action: app_badge_task.max_points_per_action
    }
  end

  def update_image image_file
    event_file_type_id = EventFileType.where(name:'app_badge_task_image').first.id
    if (image_file.original_filename.match(/jpeg|jpg/i)) then
      file_extension = '.jpg'
    elsif (image_file.original_filename.match(/png/i)) then
      file_extension = '.png'
    else
      return
    end
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
end
