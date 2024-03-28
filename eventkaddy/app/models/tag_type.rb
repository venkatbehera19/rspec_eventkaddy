class TagType < ApplicationRecord

  has_many :tags

  def self.session_type_id
    where(name:'session').first.id
  end

  def self.exhibitor_type_id
    where(name:'exhibitor').first.id
  end

  def self.session_audience_type_id
    where(name:'session-audience').first.id
  end

end
