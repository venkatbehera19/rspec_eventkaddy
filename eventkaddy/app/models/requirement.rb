class Requirement < ApplicationRecord

  belongs_to :requirement_type

  attr_accessor :name

  def createDefaults(event_id)

    @defaults = RequirementType.all

    @defaults.each_with_index do |default, index|
      @newsetting                     = Requirement.new()
      @newsetting.event_id            = event_id
      @newsetting.requirement_type_id = default.id
      @newsetting.required            = false
      @newsetting.save()
    end          	    
  end #createDefaults
end
