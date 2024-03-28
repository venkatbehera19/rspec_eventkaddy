class MobileWebSetting < ApplicationRecord

  belongs_to :mobile_web_setting_type, :foreign_key => 'type_id'
  belongs_to :event
  belongs_to :device_type, :foreign_key=>'device_type_id'
  attr_accessor :name

  def createDefaults(event_id)

    @defaults=MobileWebSettingType.all

    @defaults.each_with_index do |default, index|
      @newsetting                = MobileWebSetting.new()
      @newsetting.event_id       = event_id
      @newsetting.type_id        = default.id
      # if default.content!=nil then
      @newsetting.content        = default.default
      # end
      @newsetting.enabled        = true
      @newsetting.device_type_id = device_type_id
      @newsetting.position       = position
      @newsetting.save()
    end          	    
  end #createDefaults
end
