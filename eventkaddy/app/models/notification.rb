class Notification < ApplicationRecord

  belongs_to :event

  before_validation :change_quotation_marks_to_special_quotation_marks

  validates :description, length: { maximum: 157 }

  validate :check_for_unacceptable_characters

  serialize :session_codes, JSON

  def has_session_codes?
    session_codes.is_a?(Array) && session_codes.length > 0
  end

  def create_attendees_notifications_for_iattend_session
    # there's a limit on how large this can be. 7000 is way over,
    # about 500 is very safe. 1000 also worked for avma. don't know the real limit
    result = []
    has_session_codes? && session_codes.map {|session_code|
      Attendee.who_iattend_session_code(session_code, event_id).pluck(:account_code)
    }.
    flatten.
    uniq.
    each_slice(500) {|account_codes|
      result << AttendeesNotification.create( event_id: event_id, attendee_codes: account_codes, notification_id: id, status: 'pending')
    }
    result
  end

  # hidden notifications with types which the app cares about;
  # method creates the notification that should never be picked up
  # by the cron job which sends visible notifications
  def self.create_hidden_notification type, event_id
    offset = Event.select(:utc_offset).where(id:event_id).first.utc_offset || "+00:00"

    # carried over from original implementations; unsure how necessary it is
    where('event_id=? AND name=?', event_id, type).destroy_all

    create(
      event_id:                    event_id,
      name:                        type,
      description:                 type,
      active_time:                 Time.now.utc.strftime('%Y-%m-%d %H:%M:%S'),
      localtime:                   Time.now.localtime(offset).strftime('%Y-%m-%d %H:%M:%S'),
      status:                      'active',
      hidden_notification_type_id: HiddenNotificationType.where(name: type).first.id
    )
  end

  def check_for_unacceptable_characters

    unless description.gsub(/[A-Za-z0-9\s\~\!\@\#\$\%\^\&\*\(\)\_\+\;\:\,\.\/\?\=\-\<\>“”’]/, "").length===0
      errors.add(:description, "must only use alphanumeric characters, spaces, and the following special characters: ~!@#$%^&*()_+;:,./?=-<>“”’")
    end

    # Bergevin Request: since we don't send the name field to
    # Urban Airship, we don't have to validate this field. Therefore
    # we can add image tags and whatever we want, to display in the
    # fake notifications area. One consequence of this is allowing
    # clients to run html, but maybe ckeditor is okay for making sure
    # they don't do anything too dirty.
    
    # unless name.gsub(/[A-Za-z0-9\s\~\!\@\#\$\%\^\&\*\(\)\_\+\;\:\,\.\/\?\=\-\<\>“”’]/, "").length===0
    #   errors.add(:name, "must only use alphanumeric characters, spaces, and the following special characters: ~!@#$%^&*()_+;:,./?=-<>“”’")
    # end

    # errors.add(:name, "cannot have carriage returns (it must be all one line)") if name =~ /\r\n/
    errors.add(:description, "cannot have carriage returns (it must be all one line)") if description =~ /\r\n/

  end

  def change_quotation_marks_to_special_quotation_marks
    description.gsub!(/\s"/," “")
    description.gsub!(/"\s/,"” ")
    description.gsub!(/"$/,"”")
    description.gsub!(/"/,"“")
    description.gsub!(/'/, "’")
    description.gsub!(/`/, "")

    # changing these would disable Bergevin's plan to add images
    # name.gsub!(/\s"/," “")
    # name.gsub!(/"\s/,"” ")
    # name.gsub!(/"$/,"”")
    # name.gsub!(/"/,"“")
    # name.gsub!(/'/, "’")
    # name.gsub!(/`/, "")
  end


  def self.time_zone_aware_attributes #turn off auto-time zone adjustments for entire model
    false
  end

  #determine whether to send notification in the future
  def futureSendCheck(event)
    if (self.active_time!=nil) then

      #Rails::logger.debug "ACTIVE TIME: #{self.active_time}"

      ctime = Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')
      atime = "#{self.active_time.strftime('%Y-%m-%d %H:%M:%S')} #{event.utc_offset}"
      atime = Time.parse(atime).utc.strftime('%Y-%m-%d %H:%M:%S')
      #Rails::logger.debug "ATIME: #{atime}"
      self.active_time = atime

      #Rails::logger.debug "ATIME: #{atime}"
      #Rails::logger.debug "CTIME: #{ctime}"

      if ( Time.parse(atime) <= Time.parse(ctime) ) then
        self.status="active"
      else
        self.status="pending"
      end

    else
      self.status = "active"
      self.active_time = Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')
    end
  end

  #calculate localtime
  def setLocalTime(event)

    t_offset = event.utc_offset
    if (t_offset==nil) then
      t_offset = "+00:00" #default to UTC 0
    end

    if (self.status=="active")
      self.localtime = Time.now.localtime(t_offset).strftime('%Y-%m-%d %H:%M:%S')
    elsif (self.status=="pending")
      self.localtime = Time.parse("#{self.active_time.strftime('%Y-%m-%d %H:%M:%S')}Z").localtime(t_offset).strftime('%Y-%m-%d %H:%M:%S')
    end
  end

  def self.remove_invalid_characters str
    str.gsub(/[\'\r\n]/, ' ')
  end

  # abstracting a piece which would otherwise require an instance
  def self.push_notification event, message, pn_filters=[], options={}, external_url = nil
    key           = options.fetch :key, event.notification_app_key
    master_secret = options.fetch :master_secret, event.notification_app_master_secret
    title         = remove_invalid_characters options.fetch(:title, event.name)
    message       = remove_invalid_characters message
    url = "https://go.urbanairship.com/api/push" + (options[:validate_only] ? "/validate" : "")
    data = {
      audience:     {},
      device_types: "all",
      notification: {
        android: { title: title || '' },
        alert: message.to_s,
        ios: { sound: "true", title: title || '' }
      }
    }

    unless external_url.blank?
      data[:notification][:actions] = {
        open: {
          type: 'url',
          content: external_url
        }
      }
    end


    if event.multi_event_status == 1 && event.id != 65
      unless pn_filters.blank?
        data[:audience][:OR] = JSON.parse(pn_filters).map {|f| {tag: "event_id_#{event.id}_#{f}"} }
      else
        data[:audience] = {tag: "event_id_#{event.id}"}
      end
    else
      unless pn_filters.blank?
        data[:audience][:OR] = JSON.parse(pn_filters).map {|f| {tag:  "event_id_#{event.id}_#{f}"} }
      else
        data[:audience] = "all"
      end
    end

    ua_curl_cmd = "
      /usr/bin/curl -X POST \
      -u \"#{key}:#{master_secret}\" \
      -H \"Content-Type: application/json\" \
      -H \"Accept: application/vnd.urbanairship+json; version=3;\" \
      --data ' #{data.to_json.gsub("'"){"\\'"}}' \
      #{url} \
    "

    puts "CURL CMD #{ua_curl_cmd}"
    curl_result = `ROO_TMP='/tmp' #{ua_curl_cmd} 2>&1`
    puts "\n--------- curl cmd output ---------\n\n #{curl_result} \n------------------- \n"
    [ua_curl_cmd, curl_result]
  end

  def sendUAPushV2 options={}
    r = Notification.push_notification Event.find(event_id), description, pn_filters, options, self.web_url
    update! status: 'active', curl_result: r.to_s
    r
  end

  # immediately send push notification; old version which was a little more
  # difficult to work with I don't beleive anything uses this anymore after
  # updating notification controller and script
  def sendUAPush ua_ak, ua_ams
    r = Notification.push_notification Event.find(event_id), description, pn_filters, { key: ua_ak, master_secret: ua_ams }
    update! status: 'active', curl_result: r.to_s
    r
  end

end

    # TODO:
    #
    # in addition to the notification object, for rich messages
    # we need a message object containing some html; eg:
    #
    # "message": {
    #   "title": "Message title",
    #   "body": "<html><body><h1>Your Title</h1>Your content</html>",
    #   "content_type": "text/html"
    # }
    #
    # But this requires an upgraded UA account, costing a great deal
    # curl https://go.urbanairship.com/api/push/ \-X POST \-u "[***AUTHORIZATION STRING***]" \-H "Content-type: application/json" \-H "Accept: application/vnd.urbanairship+json; version=3;" \--data '
    # {
    #   "audience": "all",
    #   "device_types": "all",
    #   "notification":{
    #     "alert": "[***GENERAL ALERT MESSAGE***]",
    #     "android": {
    #       "style": {
    #         "type": "big_picture",
    #         "big_picture": "[***FULL IMAGE URL***]",
    #         "title": "[***BIG PICTURE TITLE***]",
    #         "summary": "[***BIG PICTURE SUMMARY***]"
    #       }
    #     }
    #   }
    # }

    # data = { 
    #   audience:     {},
    #   device_types: "all",
    #   notification: {
    #     alert: description.to_s,
    #     ios: {
    #       sound: "true" 
    #       media_attachment: {
    #         content: {
    #           title: "ios test image title",
    #           body: "ios test image body"
    #         },
    #         options: {
    #           crop: {
    #             height: 0.5,
    #             width: 0.5,
    #             x: 0.25,
    #             y: 0.25
    #           },
    #           time: 15
    #         },
    #         url: "https://newcms.eventkaddy.net/assets/ek_logo.png",
    #       },
    #       mutable_content: 1
    #     },
    #     android: {
    #       style: {
    #         type: "big_picture",
    #         big_picture: "https://newcms.eventkaddy.net/assets/ek_logo.png",
    #         title: "event kaddy test picture title",
    #         summary: "event kaddy test image"
    #       }
    #     }
    #   }
      # message: {
      #   title:        "Message title",
      #   body:         "<html><body><h1>Your Title</h1>Your content</html>",
      #   content_type: "text/html"
      # }
    # }
