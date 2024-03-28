class AppBadgeTaskType < ApplicationRecord
  # attr_accessible :name

  has_many :app_badge_tasks
  
end
