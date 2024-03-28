class Session < ApplicationRecord

  # extend ModelMethods
  attr_accessor :session_tag
  attr_accessor :other_session_tag
  attr_accessor :session_keyword
  attr_accessor :other_keyword_tag

	belongs_to :subtrack, optional: true
	belongs_to :location_mapping, optional: true

  # record type the table having the same name as the association column
  # causes many issues is it is better just to get associated records the
  # hard way
	# belongs_to :record_type, :foreign_key => 'record_type', :class_name => 'RecordType'
	belongs_to :program_type, optional: true
	belongs_to :event
	#has_many :record_comments, :dependent => :destroy
	has_many :sessions_speakers, :dependent => :destroy
	has_many :sessions_subtracks, :dependent => :destroy
	has_many :sessions_sponsors, :dependent => :destroy
	has_many :sessions_attendees, :dependent => :destroy
	has_many :sessions_trackowners, :dependent => :destroy
	has_many :survey_sessions, :dependent => :destroy
	has_many :poll_sessions, :dependent => :destroy
	has_many :speakers, :through => :sessions_speakers
	has_many :trackowners, :through => :sessions_trackowners
	has_many :subtracks, :through => :sessions_subtracks
	has_many :sponsors, :through => :sessions_sponsors, :source => 'exhibitor'
	has_many :room_layouts, :through => :sessions_room_layouts
	has_many :attendees, :through => :sessions_attendees
  has_many :surveys, :through => :survey_sessions
  has_many :polls, :through => :poll_sessions
	has_many :links
	has_many :ratings
	has_many :comments
	has_many :tags_sessions, :dependent => :destroy
	has_many :tags, :through => :tags_sessions
	has_many :feedbacks
	has_many :session_files, :dependent => :destroy
	# has_many :session_file_versions, :through => :session_files
	has_many :session_av_requirements, :dependent => :destroy
  has_many :attendee_scans, :dependent => :destroy
  has_many :session_keywords, :dependent => :destroy
  # missing session_room_layout association and destroy callback
 
 # Session.reflect_on_all_associations(:has_many).select {|a|
 #   a.options[:dependent] == :destroy
 # }.map{|a|
 #   a.name
 # }
 # [:sessions_speakers, :sessions_subtracks, :sessions_sponsors, :sessions_attendees, :sessions_trackowners, :survey_sessions, :tags_sessions, :session_files, :session_av_requirements, :attendee_scans]

  # missing :dependent => :destroy
	belongs_to :thumbnail_event_file, :foreign_key => 'thumbnail_event_file_id', :class_name => "EventFile", optional: true
  # this must be disabled for bcbs hack to use embedded video url as alterantive session files urls column
  # validate :url_check

  def update_session_file_urls_json
    update_column(:session_file_urls, generate_session_file_urls.to_json)
  end

  def generate_session_file_urls
    file_types = {
      "application/msword"                                                        => ".doc",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document"   => ".docx",
      "application/vnd.oasis.opendocument.spreadsheet"                            => ".ods",
      "application/pdf"                                                           => ".pdf",
      "text/plain"                                                                => ".txt",
      "application/rtf"                                                           => ".rtf",
      "application/vnd.ms-powerpoint"                                             => ".ppt",
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" => "pptx",
      "application/vnd.ms-excel"                                                  => ".xls",
      "application/xlsx"                                                          => ".xlsx",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"         => ".xlsx",
      "video/quicktime"                                                           => ".mov",
      "video/mp4"                                                                 => ".mp4",
      "audio/mpeg"                                                                => ".mp3",
      "application/octet-stream"                                                  => ".pez"
    }

    # sf_id is probably superfluous, I think it was just for micromanaging the
    # json, which is a scheme I'm abandoning. But I don't know if consuming
    # applications made use of it anyway. And anyway, it's probably handy for
    # debugging
    published_session_file_versions.map {|file|
      { title: file.title, url: file.path, type: file_types[file.mime_type] || '.doc', sf_id: file.sf_id, efile_id: file.event_file_id}
    }

  end

  # This subquery with final version or MAX created at looks quite awkward, but
  # it is the only way I can get it to prefer final version, then look for
  # latest created at, utilizing that data in the ON query. In a fair number of
  # tests using the forms, it seems to be okay

  # this is a bit slow when updating every session for an event. Is it possible
  # to do multiple sessions at once? Could I make this query an update query instead?

  # this is a priority to fix. It is stupidly slow when doing even ten on the
  # cms. maybe the version of SQL on the CMS is just way less efficient than
  # what I've got locally
  def published_session_file_versions

    # what would a ruby version of this look like? Probably pretty much what I had in the past, right?
    # We're just asking to loop through session files, then loop through their versions and pick the right one.
    # even if we end up doing it in 5 queries instead of one, that might be better for the hermes version of mysql.
    # It doesn't make any sense at all that 10 sessions is taking 10 minutes. It must be a bug in mysql on the server,
    # it's really not that slow.

    # result = []

    # The only problem left here is that I need title, mime type path and sf_id
    # in the result objects, which are just session file versions now
    #
    # So should I make the query a little more complex, but do the filtering logic after?

    # SessionFileVersion.find_by_sql(['
    #   SELECT
    #     session_file_versions.*, sf.title, sf.id AS sf_id, event_files.path, event_files.mime_type
    #   FROM
    #     session_file_versions
    #   LEFT OUTER JOIN session_files sf ON sf.id = session_file_versions.session_file_id
    #   LEFT OUTER JOIN event_files ON event_files.id = session_file_versions.event_file_id
    #   WHERE sf.session_id = ? AND (sf.unpublished != 1 OR sf.unpublished IS NULL)
    #   GROUP BY session_file_versions.session_file_id
    # ', id]).

    # I don't know if it works to connect this to the last one, because now I'm not just working with one group of session files at a time, so the reduce isn't as convenient

    # the other option is to just add the methods on after the fact, or access
    # them by hash keys instead of methods
    #
    # Maybe it's the left joins that are so slow... this might not even fix things on cms. But perhaps if I just add an index, everything will speed up? I should have checked that first.
    # session_files.each do |sf|
    #   next if sf.unpublished
    #   result << sf.session_file_versions.
    #     select('session_file_versions.*, sf.title, sf.id AS sf_id, event_files.path, event_files.mime_type').
    #     joins('LEFT OUTER JOIN session_files sf ON sf.id = session_file_versions.session_file_id').
    #     joins('LEFT OUTER JOIN event_files ON event_files.id = session_file_versions.event_file_id').
    #     reduce do |sv_a, sv_b|
    #       return sv_a if sv_a.final_version
    #       return sv_b if sv_b.final_version
    #       sv_a.created_at > sv_b.created_at ? sv_a : sv_b
    #     end
    # end

    # result

    SessionFileVersion.find_by_sql(['
      SELECT
        session_file_versions.*, sf.title, sf.id AS sf_id, event_files.path, event_files.mime_type
      FROM
        (SELECT
           session_file_id, IF(final_version, final_version, MAX(created_at) ) AS created_at
         FROM
           session_file_versions
         GROUP BY
           session_file_id) AS latest_session_file_versions
      INNER JOIN
        session_file_versions
      ON
        session_file_versions.session_file_id = latest_session_file_versions.session_file_id AND
        (session_file_versions.created_at = latest_session_file_versions.created_at OR session_file_versions.final_version = 1)
      LEFT OUTER JOIN session_files sf ON sf.id = session_file_versions.session_file_id
      LEFT OUTER JOIN event_files ON event_files.id = session_file_versions.event_file_id
      WHERE sf.session_id = ? AND (sf.unpublished != 1 OR sf.unpublished IS NULL)
      GROUP BY session_file_versions.session_file_id
    ', id])
  end

  def room_name
    location_mapping && location_mapping.name
  end

  def start_at_formatted
    Session.return_time_value start_at
  end

  def end_at_formatted
    Session.return_time_value end_at
  end

  def self.return_time_value val
    if !val.is_a?(String)
      result = Time.at(val.to_i).gmtime
      result = result + (1) if result.sec == 59
      result.strftime('%R:%S')
    else
      # Time.parse(val).gmtime.strftime('%T')
      # gmtime would cause the time to be translated from
      # the computer's local time, to greenwich mean time.
      # okay on production, but not okay locally
      # In the condition above, it might be okay because the
      # integer represents seconds since 1970, and cannot be
      # malformed, unlike parse, which automatically assumes
      # the local time zone
      # Time.parse(val).strftime('%T')
      ActiveSupport::TimeZone.new('UTC').parse(val).strftime('%T')
    end
  end

  def self.array_of_sessions_with_ratings event_id
    find_by_sql ["SELECT title,
    sessions.id,
    session_code,
    AVG(case when feedbacks.speaker_id IS NULL then CAST(feedbacks.rating AS DECIMAL(10,2)) else null end) AS rating,
    AVG(CAST(feedbacks.rating AS DECIMAL(10,2))) AS overall_rating
    FROM sessions
    LEFT JOIN feedbacks ON feedbacks.session_id=sessions.id AND feedbacks.created_at>='2015-04-19 00:00:00' AND feedbacks.rating>-1
    WHERE sessions.event_id=?
    GROUP BY sessions.id
    ORDER BY rating DESC",event_id]
  end

  def self.sessions_report_data event_id
    find_by_sql([
      'SELECT sessions.id,
              sessions.event_id,
              sessions.session_code,
              sessions.title,
              sessions.description,
              sessions.date,
              sessions.start_at,
              sessions.end_at,
              sessions.credit_hours,
              sessions.price,
              sessions.capacity,
              sessions.updated_at,
              location_mappings.name AS location_name,
              program_types.name AS program_type_name,
       GROUP_CONCAT( DISTINCT CONCAT(speakers.first_name, " ", speakers.last_name) SEPARATOR "|" ) AS speaker_names,
       GROUP_CONCAT( DISTINCT speakers.company                                     SEPARATOR "|" ) AS speaker_companies,
       GROUP_CONCAT( DISTINCT speakers.email                                       SEPARATOR "|" ) AS speaker_emails,
       GROUP_CONCAT( DISTINCT exhibitors.company_name                              SEPARATOR "|" ) AS exhibitor_names,
       GROUP_CONCAT( DISTINCT av_list_items.name                                   SEPARATOR "|" ) AS av_requirement_names,
       GROUP_CONCAT( DISTINCT session_av_requirements.additional_notes             SEPARATOR "|" ) AS av_requirement_notes
       FROM sessions
       LEFT OUTER JOIN location_mappings ON sessions.location_mapping_id            = location_mappings.id
       LEFT OUTER JOIN program_types     ON sessions.program_type_id                = program_types.id
       LEFT JOIN sessions_speakers       ON sessions_speakers.session_id            = sessions.id
       LEFT JOIN speakers                ON speakers.id                             = sessions_speakers.speaker_id
       LEFT JOIN sessions_sponsors       ON sessions_sponsors.session_id            = sessions.id
       LEFT JOIN exhibitors              ON sessions_sponsors.sponsor_id            = exhibitors.id
       LEFT JOIN session_av_requirements ON session_av_requirements.session_id      = sessions.id
       LEFT JOIN av_list_items           ON session_av_requirements.av_list_item_id = av_list_items.id
       WHERE sessions.event_id=?
       GROUP BY sessions.id
       ORDER BY sessions.session_code', event_id])
  end

  def all_speaker_names
    speakers.map {|s| "#{s.first_name} #{s.last_name}".strip}.join(', ')
  end

  def all_speaker_emails
    speakers.map {|s| "#{s.email}".strip}.join(', ')
  end

  def url_check
  	# 'http', not allowed on video portal
  	unless embedded_video_url.blank? || embedded_video_url =~ /\A#{URI::regexp(['https'])}\z/
  		errors.add("Embedded Video URL", "must begin with https://. Insecure connections are not currently supported.")
  	end
  end

  def next_session
    session = Session.where(event_id:event_id).order(:id).where("id > ?", id).first
    session || Session.where(event_id:event_id).order(:id).first
  end

  def previous_session
    session = Session.where(event_id:event_id).order('id DESC').where("id < ?", id).first
    session || Session.where(event_id:event_id).order('id DESC').first
  end

  # sessions.published is an old, unused field; October 2016
  # we added unpublished for use with background sync in
  # cordova app
  def published?
    !unpublished
  end

  def update_thumbnail(image_file)
    event_file_type_id      = EventFileType.where(name:'session_thumbnail').first.id
    file_extension          = File.extname image_file.original_filename

    event_file = thumbnail_event_file_id ? EventFile.find(thumbnail_event_file_id)
                                         : EventFile.create(event_id:event_id,event_file_type_id:event_file_type_id)
    cloud_storage_type_id = Event.find(event_id).cloud_storage_type_id
    unless cloud_storage_type_id.blank?
      cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
    end
    UploadEventFileImage.new(
      event_file:              event_file,
      image:                   image_file,
      target_path:             Rails.root.join('public', 'event_data', event_id.to_s, 'session_thumbnails').to_path,
      new_filename:            "#{session_code}_#{Time.now.strftime('%Y%m%d%H%M%S')}#{file_extension}",
      event_file_owner:        self,
      event_file_assoc_column: :thumbnail_event_file_id,
      new_height: 320,
      new_width: 320,
      cloud_storage_type:      cloud_storage_type
    ).call
  end

  def event_map
		self.location_mapping.blank? ? '' : self.location_mapping.event_map
	end

  def update_tags tag_array, tag_type_name
    GenerateTagsForModel.new(self, tag_array, tag_type_name).call
		true # legacy implementation; if nothing was raised in the above func, always return true
	end

  # lifted from download_sessions.xlsx
  def tags_string
    session_tags = ''

    tagType = TagType.where(name:"session").first

    #find all the existing tag groups
    tags_session = TagsSession.
      select('session_id,tag_id,tags.parent_id AS tag_parent_id,tags.name AS tag_name').
      joins('JOIN tags ON tags_sessions.tag_id=tags.id').
      where('session_id=? AND tags.tag_type_id=?', id, tagType.id)

    tag_groups = []

    tags_session.each_with_index do |tag_session, i|

      tag_groups[i] = []

      #add leaf tag
      tag_groups[i] << tag_session.tag_name
      parent_id = tag_session.tag_parent_id #acquired from above table join

      #add ancestor tags, if any
      while (parent_id!=0)
        tag = Tag.where(event_id:event_id, id:parent_id)
        if (tag.length==1) then
          tag_groups[i] << tag[0].name
          parent_id = tag[0].parent_id
        else
          parent_id = 0
        end
      end
      tag_groups[i].reverse! #reverse the order, as we followed the tag tree from leaf to root
    end

    if tag_groups.length > 0 then
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
    session_tags
  end

  def audience_tags_string
    session_tags = ''

    tagType = TagType.where(name:"session-audience").first

    #find all the existing tag groups
    tags_session = TagsSession.
      select('session_id,tag_id,tags.parent_id AS tag_parent_id,tags.name AS tag_name').
      joins('JOIN tags ON tags_sessions.tag_id=tags.id').
      where('session_id=? AND tags.tag_type_id=?', id, tagType.id)

    tag_groups = []

    tags_session.each_with_index do |tag_session, i|

      tag_groups[i] = []

      #add leaf tag
      tag_groups[i] << tag_session.tag_name
      parent_id = tag_session.tag_parent_id #acquired from above table join

      #add ancestor tags, if any
      while (parent_id!=0)
        tag = Tag.where(event_id:event_id, id:parent_id)
        if (tag.length==1) then
          tag_groups[i] << tag[0].name
          parent_id = tag[0].parent_id
        else
          parent_id = 0
        end
      end
      tag_groups[i].reverse! #reverse the order, as we followed the tag tree from leaf to root
    end

    if tag_groups.length > 0 then
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
    session_tags
  end

  def sponsors_string
    sponsors.map(&:company_name).join('##')
  end

  def session_file_strings
    session_file_urls      = ''
    session_file_titles    = ''
    session_file_filetypes = ''
    session_files.each_with_index do |file, i|
      if i < (session_files.length-1) && file.session_file_versions.length > 0
        session_file_urls   += "#{file.session_file_versions.order(created_at: :desc).first&.event_file.name}, "
        session_file_titles += "#{file.title}, "
        session_file_filetypes   += "#{file.session_file_versions.order(created_at: :desc).first&.event_file&.path.to_s.split('.').last}, "
      elsif file.session_file_versions.length > 0
        session_file_urls   += "#{file.session_file_versions.order(created_at: :desc).first&.event_file&.name}"
        session_file_titles += "#{file.title}"
        session_file_filetypes   += "#{file.session_file_versions.order(created_at: :desc).first&.event_file&.path.to_s.split('.').last}"
      end
    end
    {
      session_file_urls:      session_file_urls,
      session_file_titles:    session_file_titles,
      session_file_filetypes: session_file_filetypes
    }
  end

  def return_authenticated_url(event_id,file_path)
    ReturnAWSUrl.new(event_id,file_path).call
  end

end
