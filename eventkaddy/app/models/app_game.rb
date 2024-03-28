class AppGame < ApplicationRecord
  # attr_accessible :event_id, :active, :description, :name

  belongs_to :event
  has_many :app_badges

  def self.detailed_game_info id
    app_game = find id
    {
      id:            id,
      name:          app_game.name,
      description:   app_game.description,
      status:        app_game.active ? "Active" : "Inactive",
      edit_url:      "/app_games/#{id}/edit",
      new_badge_url: "/app_badges/new",
      badges:        app_game.app_badges.order(:position).map {|b| 
                       {
                         position:   b.position,
                         image:      !b.event_file.blank? ? (b.event_file.cloud_storage_type_id.blank? ? b.event_file.path : b.event_file.return_authenticated_url()['url']) : 'No image.',
                         name:       b.name,
                         task_count: b.app_badge_tasks.count,
                         tasks_url:  "/app_badges/#{b.id}",
                         edit_url:   "/app_badges/#{b.id}/edit",
                         delete_url: "/app_badges/#{b.id}"
                       } 
                     }
    }
  end
end
