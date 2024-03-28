# Script to be run by cron job to send pending notifications

require_relative '../config/environment.rb'
require_relative './settings.rb'

ActiveRecord::Base.establish_connection(
  adapter: "mysql2", host: @db_host, username: @db_user,
  password: @db_pass, database: @db_name)

ctime = Time.now.utc
puts "current utc time: #{ctime}"

Notification.where(status:'pending')
  .each do |notification|
    begin
      atime = Time.parse(
        "#{notification.active_time.strftime('%Y-%m-%d %H:%M:%S')}Z"
      )

      puts "active time: #{atime}"

      if atime <= ctime && !notification.unpublished? && !@notification.on_home_feed_announcement
        puts "notification id #{notification.id} attempt to set to active"

        # redundant line that updates the status first before trying to send a notification,
        # so that notifications which fail or can't save the output of curl_result for some
        # reason don't continuously try to send
        # ie line 150 from notification.rb model definition
        # also, don't do validations at this point (so note the missing plural of update_attribute)

        if notification.update_attribute(:status, 'active')
          unless notification.has_session_codes?
            notification.sendUAPushV2 if notification.push_notification?
          else
            puts "notification has session_codes; generating attendees_notifications"
            puts notification.create_attendees_notifications_for_iattend_session.inspect
          end
        else
          puts "notification failed to save status as active. Did not send UA Push"
        end
      else
        puts "notification id #{notification.id} still pending"
      end
    rescue StandardError => e
      puts "error : #{e}"
    end
  end


# we assume all attendees_notifications should be sent one at a time
# (each time this script is invoked), until no more are pending, as they
# should not be created in advance of the parent notifications active state
attendees_notifications = AttendeesNotification.where(status: "pending")
if attendees_notifications.length > 0
  a_n = attendees_notifications.first
  puts "#{attendees_notifications.length} attendees_notifications pending"

  # do this first so if anything goes wrong we don't try over and over.
  if a_n.update_attribute(:status, 'active')

    puts "Sending attendees notification with id #{a_n.id} for notification with id #{a_n.notification_id}."

    notification = Notification
      .select('id, pn_filters, session_codes, name, status, active_time, event_id, description')
      .where(id: a_n.notification_id)
      .first

    if notification
      if a_n.has_attendee_codes?
        pn_filters = notification.pn_filters && JSON.parse(notification.pn_filters) || []
        notification.pn_filters = a_n.attendee_codes.to_s
        notification.sendUAPushV2
        a_n.update_attribute :curl_result, notification.curl_result
      else
        puts "No notification sent, attendees_notification.attendee_codes did not have any attendee codes or was not an array."
      end
    else
      puts "Error, notification_id #{a_n.notification_id} did not exist, no notification sent."
    end

  end # if update attr status to active
end # if attendees_notifications > 0


