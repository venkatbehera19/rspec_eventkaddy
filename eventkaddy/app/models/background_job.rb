class BackgroundJob < ApplicationRecord
  belongs_to :entity, polymorphic: true
end
