###########################################
# Ruby script to import notification data 
# from spreadsheet into EventKaddy CMS
###########################################

# this loads rails, active record, and the dev database
require_relative '../../config/environment.rb' 

# abtracted methods shared by xlsx imports
require_relative '../import.rb'

# spreadsheet gem
require 'roo'

# these two lines allow you to change the database that was connected 
# to by loading environement.rb;
require_relative '../settings.rb'
Import.connect_to_database

EVENT_ID         = ARGV[0]
SPREADSHEET_PATH = ARGV[1]
JOB_ID           = ARGV[2]
USER_ID          = ARGV[3]

# EVENT_ID         = 20
# SPREADSHEET_PATH = './ek_scripts/config_page_scripts/n2.xlsx'
# JOB_ID = Job.try_to_create_job(
#            name:     "my test",
#            event_id: EVENT_ID)[:job_id]

if JOB_ID
  job = Job.find JOB_ID
  job.update!(
    original_file: SPREADSHEET_PATH,
    row:           0,
    status:        'In Progress')
end

job.start {

  notification_import = Import.new({
    spreadsheet_path: SPREADSHEET_PATH,
    possible_fields: [
      ['id'], ['name'], ['description'], 
      ['on-site time', 'on site time', 'localtime', 'local time'],
      ['active_time', 'active time'], 
      ['status'], 
      ['notification filters', 'pn_filter', 'notifications_filter']
    ]
  })

  event = Event.find EVENT_ID

  notification_import.spreadsheet.sheets.each do |sheet|

    notification_import.spreadsheet.default_sheet = sheet

    job.update!(
      total_rows: notification_import.spreadsheet.last_row - 1,
      status:     'Processing Rows')

    2.upto(notification_import.spreadsheet.last_row) do |row_number|

      notification_import.row_number = row_number
      job.row                   = job.row + 1
      job.write_to_file if job.row % job.rows_per_write == 0

      id = notification_import.numberValueFor( 'id' )

      # Notifications are a bit convoluted. The process is like this for the form version:
      # form active_time is populated with localtime if available, or the current time
      # the form is posted, and active time is then filtered through futureSendCheck to
      # decide whether it is active or not (auto active if active_time is nil, frighteningly
      # enough), using the utc offset on the active_time posted to turn it into the right number
      # for the server.
      # After that, localtime is then calculated by filtering active_time through setLocalTime,
      # essentially turning it back into the active_time that was originally posted. This system
      # should be changed, but because missent notifications would be embarassing, it is hard to 
      # do so, so this script imitates that process.

      # could maybe be extracted into some more generic comma delimited list
      # to array function, but because there's some logic about camelCase that
      # is less generalizable, I will leave it for now. It maybe belongs in a
      # utlitiy module or even just as a class method on the 
      # notification model itself; we have to use it in a few places, since
      # multiple models have a pn_filters field
      pn_filters = notification_import.valueFor( 'notification filters' )
      unless pn_filters.blank?
        pn_filters = pn_filters
        .split(',')
        .map(&:strip)
        .map {|a| 
          ary = a.split
          [ary[0][0].downcase + ary[0][1..-1]] # downcase first letter
          .concat(ary[1..-1].map(&:capitalize)).join # cap first letter
        }
      else
        pn_filters = nil
      end

      event_filters = Event.find(EVENT_ID).all_pn_filters

      pn_filters && pn_filters.each {|f|
        unless event_filters.include? f
          raise "Invalid notification filter \"#{f}\". Possible filters: #{event_filters.join(', ')}"
        end
      }

      pn_filters && pn_filters = pn_filters.to_s

      notification_attrs = {
        event_id:    EVENT_ID,
        name:        notification_import.valueFor( 'name' ),
        description: notification_import.valueFor( 'description' ),
        active_time: notification_import.valueFor( 'on site time' ),
        pn_filters:  pn_filters
      }

      # roo will autoconvert date formatted cells to DateTime; Our export delivers
      # Strings. If we receive a date-time, conform to string always
      # we will allow active record to determine how that string is saved as a time
      if notification_attrs[:active_time].class == DateTime
        notification_attrs[:active_time] = notification_attrs[:active_time].strftime('%Y-%m-%d %H:%M:%S')
      end

      # "2015-10-02 23:20:50".match /^\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}$/

      unless notification_attrs[:active_time].match /^\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}$/
        raise "On-site time \"#{notification_attrs[:active_time]}\" 
               does not conform to YYYY-MM-DD HH-MM-SS."
      end

      if id

        notification = Notification.find id

        if notification.event_id != EVENT_ID.to_i
          raise "Notification id belonged to another event. 
            Please leave id blank to create new notifications, or
            upload a spreadsheet you've downloaded and updated instead."
        end

        notification.update! notification_attrs.reject {|k,v| k==:active_time}

        # set active_time without saving it, in case it fails !active condition
        notification.active_time = notification_attrs[:active_time]

      else
        notification = Notification.new notification_attrs
      end

      # if we're updating an already active notification, we're not worried about
      # it sending immediately, as only "pending" status notifications are sent.
      already_active = notification.status == "active"

      notification.futureSendCheck event		
      notification.setLocalTime event

      if notification.status=="active" && !already_active
        raise "Import was halted because notification:
               \"#{notification.name}\" would have been sent immediately."
      else
        notification.save
      end
    end
  end
}

