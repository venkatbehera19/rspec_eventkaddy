# the mixins/finders pattern is something I read a long time ago; we keep
# the existing ones as legacy, but shouldn't make them anymore. My opinion
# now is that "Finder" is already the concept encompassed by an active record
# model, and it makes no sense to have a module that is only useful to one
# class.

module SettingFinders

  def return_cms_settings(event_id)
    type_id = SettingType.where(name:'cms_settings').first.id
    s       = Setting.where(event_id:event_id, setting_type_id:type_id)
    if s.length > 0 

      settings         = s.first

      default_settings = Setting.default_settings

      missing_settings = Setting.cms_props - settings.json.keys.map(&:to_sym)

      missing_settings.each do |ms|

        # this odd little slice of code just means set the value to
        # true if it's a hide option, and false if it's a show option (or
        # any other option). We are taking symbols, converting them to
        # strings just so we can add = to them, and send that that as
        # a message to the setter method on the settings instance.
        # ie: settings.hide_session_form_session_codes=true
        if default_settings.json.has_key? ms.to_s
          # if there is a default for the missing setting, use that
          # default, otherwise hide it.
          settings.send ms.to_s + '=', default_settings.send(ms)
        elsif ms.to_s.include? "hide"
          settings.send ms.to_s + '=', true
        else
          settings.send ms.to_s + '=', false
        end

      end

      settings
    else 
      default_settings          = Setting.default_settings
      default_settings.event_id = event_id

      missing_settings = Setting.cms_props - default_settings.json.keys.map(&:to_sym)

      missing_settings.each do |ms|

        if ms.to_s.include? "hide"
          default_settings.send ms.to_s + '=', true
        else
          default_settings.send ms.to_s + '=', false
        end

      end
      default_settings
    end
  end

  def return_guest_view_settings(event_id)
    return_setting_by_type 'guest_view_settings', event_id
  end

  def return_cordova_ekm_settings(event_id)
    return_setting_by_type 'cordova_ekm_settings', event_id
  end

  def return_cordova_window_settings(event_id)
    return_setting_by_type 'cordova_window_settings', event_id
  end

  # deprecated
  def return_cordova_strings(event_id)
    return_setting_by_type 'cordova_strings', event_id
  end

  # deprecated
  def return_cordova_booleans(event_id)
    return_setting_by_type 'cordova_booleans', event_id
  end

  def return_cordova_booleans_or_false(event_id)
    type_id = SettingType.where(name:'cordova_booleans').first.id
    s       = Setting.select('event_id, setting_type_id, json').where(event_id:event_id, setting_type_id:type_id)
    s.length > 0 ? s.first : false
  end

  def return_attendee_portal_settings event_id
    type_id = SettingType.where(name:'attendee_portal_settings').first.id
    s       = Setting.where(event_id:event_id, setting_type_id:type_id)
    s.length > 0 ? s.first : Setting.new(event_id:event_id, setting_type_id:type_id)
  end

  def return_exhibitor_portal_settings(event_id)
    type_id = SettingType.where(name:'exhibitor_portal_settings').first.id
    s       = Setting.where(event_id:event_id, setting_type_id:type_id)
    s.length > 0 ? s.first : Setting.new(event_id:event_id, setting_type_id:type_id)
  end

  def return_exhibitor_portal_settings_or_false(event_id)
    type_id = SettingType.where(name:'exhibitor_portal_settings').first.id
    s       = Setting.select('event_id, setting_type_id, json').where(event_id:event_id, setting_type_id:type_id)
    s.length > 0 ? s.first : false
  end

  def return_speaker_portal_settings(event_id)
    type_id = SettingType.where(name:'speaker_portal_settings').first.id
    s       = Setting.where(event_id:event_id, setting_type_id:type_id)
    s.length > 0 ? s.first : Setting.new(event_id:event_id, setting_type_id:type_id)
  end

  def return_speaker_portal_settings_or_false(event_id)
    type_id = SettingType.where(name:'speaker_portal_settings').first.id
    s       = Setting.select('event_id, setting_type_id, json').where(event_id:event_id, setting_type_id:type_id)
    s.length > 0 ? s.first : false
  end

  def return_video_portal_booleans(event_id)
    type_id = SettingType.where(name:'video_portal_booleans').first.id
    s       = Setting.where(event_id:event_id, setting_type_id:type_id)
    s.length > 0 ? s.first : Setting.new(event_id:event_id, setting_type_id:type_id)
  end

  def return_program_feed_booleans(event_id)
    type_id = SettingType.where(name:'program_feed_booleans').first.id
    s       = Setting.where(event_id:event_id, setting_type_id:type_id)
    s.length > 0 ? s.first : Setting.new(event_id:event_id, setting_type_id:type_id)
  end

  def return_video_portal_strings(event_id)
    type_id = SettingType.where(name:'video_portal_strings').first.id
    s       = Setting.where(event_id:event_id, setting_type_id:type_id)
    s.length > 0 ? s.first : Setting.new(event_id:event_id, setting_type_id:type_id)
  end

  def return_video_portal_headings(event_id)
    type_id = SettingType.where(name:'video_portal_headings').first.id
    s       = Setting.where(event_id:event_id, setting_type_id:type_id)
    s_default = Setting.where(event_id:0, setting_type_id:type_id)
    if s.length > 0 
      return s.first
    elsif s_default.length > 0
      return s_default.first
    else
      return Setting.new(event_id:event_id, setting_type_id:type_id)
    end
  end

  def return_video_portal_headings_or_false(event_id)
    type_id = SettingType.where(name:'video_portal_headings').first.id
    s       = Setting.select('event_id, setting_type_id, json').where(event_id:event_id, setting_type_id:type_id)
    s.length > 0 ? s.first : false
  end

  def return_video_portal_contents(event_id)
    type_id = SettingType.where(name:'video_portal_contents').first.id
    s       = Setting.where(event_id:event_id, setting_type_id:type_id)
    s.length > 0 ? s.first : Setting.new(event_id:event_id, setting_type_id:type_id)
  end

  def return_video_portal_contents_or_false(event_id)
    type_id = SettingType.where(name:'video_portal_contents').first.id
    s       = Setting.select('event_id, setting_type_id, json').where(event_id:event_id, setting_type_id:type_id)
    s.length > 0 ? s.first : false
  end

  def return_registration_portal_settings(event_id)
    type_id = SettingType.where(name:'registration_portal_settings').first.id
    s       = Setting.where(event_id:event_id, setting_type_id:type_id)
    s.length > 0 ? s.first : Setting.new(event_id:event_id, setting_type_id:type_id)
  end

  def return_cached_settings_for_registration_portal(args)
    Rails.cache.fetch("registration_portal_settings-cache#{args[:event_id]}}", force: args.fetch(:force_refresh, false)) {
      Setting.return_registration_portal_settings(args[:event_id])}
    Rails.cache.read "registration_portal_settings-cache#{args[:event_id]}}"
  end

  def return_simple_registration_settings(event_id)
    type_id = SettingType.where(name:'simple_registration_settings').first.id
    s       = Setting.where(event_id:event_id, setting_type_id:type_id)
    s.length > 0 ? s.first : Setting.new(event_id:event_id, setting_type_id:type_id)
  end

  def return_speaker_registration_settings(event_id)
    type_id = SettingType.where(name:'speaker_registration_settings').first.id
    s       = Setting.where(event_id:event_id, setting_type_id:type_id)
    s.length > 0 ? s.first : Setting.new(event_id:event_id, setting_type_id:type_id)
  end

  def return_exhibitor_registration_portal_settings(event_id)
    type_id = SettingType.where(name:'exhibitor_registration_portal_settings').first.id
    s       = Setting.where(event_id:event_id, setting_type_id:type_id)
    s.length > 0 ? s.first : Setting.new(event_id:event_id, setting_type_id:type_id)
  end
  
  def return_video_portal_booleans_or_false(event_id)
    type_id = SettingType.where(name:'video_portal_booleans').first.id
    s       = Setting.select('event_id, setting_type_id, json').where(event_id:event_id, setting_type_id:type_id)
    s.length > 0 ? s.first : false
  end

  def return_video_portal_strings_or_false(event_id)
    type_id = SettingType.where(name:'video_portal_strings').first.id
    s       = Setting.select('event_id, setting_type_id, json').where(event_id:event_id, setting_type_id:type_id)
    s.length > 0 ? s.first : false
  end

  def return_cms_settings_or_false(event_id)
    type_id = SettingType.where(name:'cms_settings').first.id
    s       = Setting.select('event_id, setting_type_id, json').where(event_id:event_id, setting_type_id:type_id)
    s.length > 0 ? s.first : false
  end

  def return_attendee_badge_settings(event_id)
    type_id =  SettingType.find_by(name: 'attendee_badge_portal_settings').id
    s       =  Setting.where(event_id:event_id, setting_type_id:type_id)
    s.length > 0 ? s.first : Setting.new(event_id:event_id, setting_type_id:type_id)
  end

  private

  # some of the above methods could be refactored to use this one.
  def return_setting_by_type type_name, event_id
    type_id = SettingType.where(name:type_name).first.id
    s       = Setting.where(event_id:event_id, setting_type_id:type_id)
    s.length > 0 ? s.first : Setting.new(event_id:event_id, setting_type_id:type_id)
  end

end
