require_relative '../settings.rb' #config
require 'active_record'
require_relative '../../config/environment.rb'
require_relative './export-helpers.rb'

ActiveRecord::Base.establish_connection(:adapter => "mysql2", :host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

EVENT_ID = ARGV[0]
JOB_ID   = ARGV[1]

if JOB_ID
  job = Job.find JOB_ID
  job.update!(original_file:@db_name, row:0, status:'In Progress')
end

# lifted from xlsx.axlsx download_sessions file and modified slightly
def session_data job, event_id
  data = [['Session Code','Title','Date','Start Time','End Time','Room','Description','Learning Objective','Session Tags','Audience Tags','Speaker Honor Prefix','Speaker First Name','Speaker Last Name','Speaker Honor Suffix','Speaker Title','Speaker Biography','Online Speaker Photo URL','Speaker Company','Speaker Email','Speaker Tax ID','Speaker Code','Credit Hours','Price','Capacity','Published','Session Sponsors','Survey URL','Polling URL','Program Type','Ticketed','Record','Record Type','Video Thumbnail','Video iPhone','Video iPad','Video Android','Twitter Tag','Session File Titles','Session File Filenames','Session File Extensions','Session Cancelled', 'Custom Filter 1', 'Custom Filter 2', 'Custom Filter 3', 'Custom Fields', 'Promotion', 'Keywords', 'Premium Access','Track Subtrack']]
  sessions = Session.where(event_id:event_id)
  job.update!(total_rows: sessions.length, status:'Fetching Rows From Database')
  sessions.each do |session|

    program_type = ''
    location_mapping = ''

    program_type     = session.program_type.name     if session.program_type!=nil
    location_mapping = session.location_mapping.name if session.location_mapping!=nil

    program_area     = ''
    program_category = ''
    session_tags     = ''
    audience_tags    = ''

    tagType = TagType.where(name:"session").first

    #find all the existing tag groups
    tags_session = TagsSession.
      select('session_id,tag_id,tags.parent_id AS tag_parent_id,tags.name AS tag_name').
      joins('JOIN tags ON tags_sessions.tag_id=tags.id').
      where('session_id=? AND tags.tag_type_id=?',session.id,tagType.id)

    tag_groups = []

    tags_session.each_with_index do |tag_session, i|

      tag_groups[i] = []

      #add leaf tag
      tag_groups[i] << tag_session.tag_name
      parent_id = tag_session.tag_parent_id #acquired from above table join

      #add ancestor tags, if any
      while (parent_id!=0)
        tag = Tag.where(event_id:session[:event_id],id:parent_id)
        if tag.length==1
          tag_groups[i] << tag[0].name
          parent_id = tag[0].parent_id
        else
          parent_id = 0
        end
      end
      tag_groups[i].reverse! #reverse the order, as we followed the tag tree from leaf to root
    end

    if tag_groups.length > 0
      tag_groups.each_with_index do |tag_group, i|
        tag_group.each_with_index do |tag, i|
          unless (i+1)===tag_group.length
            session_tags += "#{tag}||"
          else
            session_tags += "#{tag}"
          end
        end
        unless (i+1)===tag_groups.length
          session_tags += "^^"
        end
      end
    end

    tagType = TagType.where(name:"session-audience").first

    #find all the existing tag groups
    tags_session = TagsSession.select('session_id,tag_id,tags.parent_id AS tag_parent_id,tags.name AS tag_name').joins('
        JOIN tags ON tags_sessions.tag_id=tags.id').where('session_id=? AND tags.tag_type_id=?',session.id,tagType.id)

    tag_groups = []

    tags_session.each_with_index do |tag_session, i|

      tag_groups[i] = []

      #add leaf tag
      tag_groups[i] << tag_session.tag_name
      parent_id = tag_session.tag_parent_id #acquired from above table join

      #add ancestor tags, if any
      while (parent_id!=0)
        tag = Tag.where(event_id:session[:event_id],id:parent_id)
        if tag.length==1
          tag_groups[i] << tag[0].name
          parent_id = tag[0].parent_id
        else
          parent_id = 0
        end
      end
      tag_groups[i].reverse! #reverse the order, as we followed the tag tree from leaf to root
    end

    if tag_groups.length > 0
      tag_groups.each_with_index do |tag_group, i|
        tag_group.each_with_index do |tag, i|
          unless (i+1)===tag_group.length
            audience_tags += "#{tag}||"
          else
            audience_tags += "#{tag}"
          end
        end
        unless (i+1)===tag_groups.length
          audience_tags += "^^"
        end
      end
    end


    sponsors = ''
    session.sponsors.each_with_index do |sponsor, i|
      unless (i+1)===session.sponsors.length
        sponsors += "#{sponsor.company_name}##"
      else
        sponsors += "#{sponsor.company_name}"
      end
    end

    if session.start_at!=nil
      session_start_at = Time.at(session.start_at.to_f + 0).gmtime.strftime('%T')
    else
      session_start_at = ''
    end

    if session.end_at!=nil
      session_end_at = Time.at(session.end_at.to_f + 0).gmtime.strftime('%T')
    else
      session_end_at = ''
    end

    if session.date!= nil
      date = session.date.strftime('%F')
    else
      date = ''
    end

    session_file_urls   = ''
    session_file_titles = ''
    session_filetypes   = ''

    session.session_files.each_with_index do |file, i|
      if (i < (session.session_files.length-1) && file.session_file_versions.length > 0)
        session_file_urls   += "#{file.session_file_versions.order('created_at desc').first.event_file.name}, "
        session_file_titles += "#{file.title}, "
        session_filetypes   += "#{file.session_file_versions.order('created_at desc').first.event_file.path.split('.').last}, "
      elsif file.session_file_versions.length > 0
        session_file_urls   += "#{file.session_file_versions.order('created_at desc').first.event_file.name}"
        session_file_titles += "#{file.title}"
        session_filetypes   += "#{file.session_file_versions.order('created_at desc').first.event_file.path.split('.').last}"
      end
    end

    record_type = RecordType.find(session.record_type).record_type unless session.record_type.blank?
    published = session.published ? "true" : ""
    cancelled = session.session_cancelled ? "true" : ""

    if session.speakers.length > 0

      session.speakers.each do |speaker|

        data << [session.session_code,session.title,date,session_start_at,session_end_at,location_mapping,session.description,session.learning_objective,session_tags,audience_tags,speaker.honor_prefix,speaker.first_name,speaker.last_name,speaker.honor_suffix,speaker.title,speaker.biography,speaker.photo_filename,speaker.company,speaker.email,speaker.fd_tax_id,speaker.speaker_code,session.credit_hours,session.price,session.capacity,published,sponsors,session.survey_url,session.poll_url,program_type,session.ticketed,session.wvctv,record_type,session.video_thumbnail,session.video_iphone,session.video_ipad,session.video_android,session.tag_twitter,session_file_titles,session_file_urls,session_filetypes,cancelled, session.custom_filter_1,session.custom_filter_2,session.custom_filter_3,session.custom_fields,session.promotion,session.keyword,session.premium_access,session.track_subtrack]
      end

      job.row = job.row + 1
      job.write_to_file if job.row % job.rows_per_write == 0

    else

      data << [session.session_code,session.title,date,session_start_at,session_end_at,location_mapping,session.description,session.learning_objective,session_tags,audience_tags,"","","","","","","","","","","",session.credit_hours,session.price,session.capacity,published,sponsors,session.survey_url,session.poll_url,program_type,session.ticketed,session.wvctv,record_type,session.video_thumbnail,session.video_iphone,session.video_ipad,session.video_android,session.tag_twitter,session_file_titles,session_file_urls,session_filetypes,cancelled, session.custom_filter_1,session.custom_filter_2,session.custom_filter_3,session.custom_fields,session.promotion,session.keyword,session.premium_access,session.track_subtrack]

      job.row = job.row + 1
      job.write_to_file if job.row % job.rows_per_write == 0
    end
  end
  data
end

job.start() {
  event_name = Event.find( EVENT_ID ).name

  config_page_export_data(
    job,
    "download_sessions_full_for_#{event_name.downcase.gsub(' ', '_')}.xlsx", # filename
    'sessions',                                                              # sheetname
    "Download Sessions Full for #{event_name}",                              # link label
    EVENT_ID,
    session_data( job, EVENT_ID )
  )
}


