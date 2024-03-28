class SpeakerFileType < ApplicationRecord
	include ActiveModel::ForbiddenAttributesProtection

  has_many :speaker_files
end
