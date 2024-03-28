
class Attendee < ApplicationRecord

  # this require should be able to happen somewhere else; there's no reason it
  # should really be at the top of a class file
  require 'rqrcode_png'
  require 'rqrcode'

  belongs_to :user, :foreign_key => 'user_id', optional: true
  belongs_to :attendee_type, optional: true
  has_many :session_recommendations
  has_many :exhibitor_recommendations
  has_many :comments
  has_many :ratings
  has_many :feedbacks
  has_many :sessions_attendees, :dependent => :destroy
  has_many :sessions, :through => :sessions_attendees
  has_many :exhibitor_attendees, :dependent => :destroy
  has_many :exhibitors, :through => :exhibitor_attendees
  has_many :booth_owners, :dependent => :destroy
  has_many :attendees_exhibitor_products#, :dependent => :destroy # Don't destroy because we may want to keep that data?

  # don't know why this isn't plural, but it seems to work.
  has_many :attendees_scavenger_hunt_item, :dependent => :destroy
  has_many :scavenger_hunt_item, :through => :attendees_scavenger_hunt_item

  has_many :attendees_app_badges, :dependent => :destroy
  has_many :attendees_app_badge_tasks, :dependent => :destroy
  has_many :app_badges, :through => :attendees_app_badges
  has_many :attendees_app_badge_tasks
  has_many :app_badge_tasks, :through => :attendees_app_badge_tasks

  has_many :survey_responses, :dependent => :destroy
  has_many :responses, :through => :survey_responses

  belongs_to :event_file_photo, :foreign_key => 'photo_event_file_id', :class_name => "EventFile", optional: true

  #has_one :exhibitor, :through => :booth_owners

  has_many :attendee_text_uploads
  has_many :tags_attendees, :dependent => :destroy
  has_many :tags, :through => :tags_attendees
  has_many :background_jobs, as: :entity

  has_many :attendee_scans, :foreign_key => 'initiating_attendee_id'

  has_many :attendee_tickets

  before_create :set_slug, :set_username

  after_save :update_account_code_if_blank

  before_destroy :track_destroyed_attendee
  before_update :set_username

  has_many :attendee_products
  has_many :attendee_badge_prints
  # validates :password, confirmation: { case_sensitive: true }

  validates :password, confirmation: { case_sensitive: true }, on: :create

  # validates :username, uniqueness: {  scope: :event_id, case_sensitive: false, allow_blank: true, allow_nil: true }, on: :update

  # def event_next_attendee
  #   Attendee.where("event_id = ? and id > ?",self.event_id, self.id).first
  # end

  # def event_previous_attendee
  #   Attendee.where("event_id = ? and id < ?", self.event_id, self.id).last
  # end

  def send_notification content, options={}
    unless messaging_notifications_opt_out
      Notification.push_notification Event.find(event_id), content, [account_code].to_s, options
    else
      false
    end
  end

  # should probably take id or code, as an array in a hash, but this is a just
  # a shortcut for testing anyway. It's also missing the flag attribute, so
  # don't use this in production unless you update it
  #
  # also, it turns out session_id is a VARCHAR column. That's really bad! no
  # wonder searches on that table are so slow.
  def add_session_favourite code
    SessionsAttendee.where(
      attendee_id: id,
      session_id:  Session.where(event_id:event_id, session_code:code).first.id,
      session_code: code,
    ).first_or_create
  end

  def remove_session_favourite code
    SessionsAttendee.where(
      attendee_id: id,
      session_id:  Session.where(event_id:event_id, session_code:code).first.id
    ).destroy_all
  end

  # this isn't really the right word for it... what I mean is attendees
  # who are exhibitors that no longer have a connection to an exhibitor
  # should be changed to standard attendees
  def self.cleanup_abandoned_booth_owners event_id
    exhibitor_type_id = AttendeeType.where(name:'Exhibitor').first.id
    standard_type_id = AttendeeType.where(name:'Standard Attendee').first.id

    # active record requires id in select to be able to construct update query
    select('attendees.id, account_code').
      joins('LEFT JOIN booth_owners ON booth_owners.attendee_id=attendees.id').
      where(event_id: event_id, attendee_type_id: exhibitor_type_id).
      where('exhibitor_id IS NULL').
      each {|a| a.update_column(:attendee_type_id, standard_type_id) }
  end

  def self.who_iattend_session_code code, event_id
    # two escapes happen here; first the active record ? style escaping (which hopefully protects us
    # against injections), and second the Regexp escape, which should help ensure the session code is not
    # treated as special regexp characters.
    # You can use this method like Attendee.select('id').who_iattend_session_code 'WS9', 23 if needed; ie
    # the return value of select still has this method, conveniently
    where(event_id:event_id).
      where('iattend_sessions REGEXP ?', "(,|^)#{Regexp.escape( code.to_s )}(,|$)") # code between commas, code at beginning, or code at end
  end

  def track_destroyed_attendee
    DestroyedAttendee.create(event_id:event_id, attendee_id:id, account_code:account_code)
  end

  def qr_image_full_path
		Rails.root.join('public', 'event_data', event_id.to_s, 'attendee_qr_images', "#{event_id}_#{account_code}_#{first_name}_#{last_name}_qr_image.png")
  end

  def qr_image_relative_path
		"/event_data/#{event_id}/attendee_qr_images/#{event_id}_#{account_code}_#{first_name}_#{last_name}_qr_image.png"
  end

  def generate_qr_image
    # default is account code for ATTENDEE_AUTH_VAL, but for some events
    # it has been attendee.id; shouldn't be necessary to abstract, but just
    # a warning
    #qr_text = "attendee:#{account_code}"
    qr_text = "#{account_code}"

		directory_path = Rails.root.join('public', 'event_data', event_id.to_s, 'attendee_qr_images')
    FileUtils.mkdir_p(directory_path) unless File.directory?(directory_path)
    RQRCode::QRCode.
      new(qr_text, :level => :l ).
      to_img.
      resize(600, 600).
      save(qr_image_full_path)
    cloud_storage_type_id   = Event.find(event_id).cloud_storage_type_id
    cloud_storage_type      = nil
    unless cloud_storage_type_id.blank?
      cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
    end
  
    UploadEventFileImage.new(
      target_path:             Rails.root.join('public', 'event_data', event_id.to_s, 'attendee_qr_images'),
      new_filename:            "#{event_id}_#{account_code}_#{first_name}_#{last_name}_qr_image.png",
      cloud_storage_type:      cloud_storage_type
    ).call
    qr_image_relative_path
  rescue RQRCode::QRCodeRunTimeError
    "QR Code could not be generated due to attendee account code length."
  end

  def qr_image
    File.exist?(qr_image_full_path) ? qr_image_relative_path : generate_qr_image
  end

  # account_code, attendee_name, attendee_group, total_count, count for each type, count for each group
  # count for each group wasn't working; using stats_summary_for_event instead and an n+1 query
  # def self.with_scan_stats_for_event event_id
  #   # this method may need to take an argument which specifies
  #   # the column to be grouped by; and its matching report may
  #   # need to determine that by a new table
  #   select("
  #          CONCAT_WS(' ', first_name, last_name) AS name,
  #          attendees.id,
  #          account_code,
  #          business_unit                          AS 'group',
  #          COUNT(initiating_attendee_id)          AS total,
  #          COUNT(target_attendee_id)              AS meetings_count,
  #          COUNT(session_id)                      AS session_scans_count,
  #          COUNT(exhibitor_id)                    AS exhibitor_scans_count,
  #          COUNT(location_mapping_id)             AS location_scans_count,
  #          GROUP_CONCAT(target_attendees.g_count) AS group_counts
  #          ").
  #     where(event_id: event_id).
  #     joins(:attendee_scans).
  #     joins("LEFT OUTER JOIN (
  #               SELECT a.id, CONCAT_WS(':', a.business_unit, COUNT(*)) AS g_count
  #               FROM attendees a
  #               GROUP BY business_unit
  #     ) target_attendees ON target_attendees.id=target_attendee_id").
  #     group("attendees.id").
  #     as_json. # misnomer, to_json is a string of json, as_json is a ruby hash
  #     map {|a| a['attendee'] }
  # end

  def destroy_game_and_survey_data game_data = true, survey_data = true
    results = {}

    if game_data
      # not used for game currently, but may be in the future
      # attendee_gps_data_points
      # attendee_logins

      # attendees_app_badge_tasks isn't used yet, but it might be in the future
      aab_length  = attendees_app_badges.length
      aabt_length = attendees_app_badge_tasks.length
      ashi_length = attendees_scavenger_hunt_item.length
      sa_length = sessions_attendees.length

      if attendees_app_badges.destroy_all
        results[:attendees_app_badges_deleted] = aab_length
      end

      if attendees_app_badge_tasks.destroy_all
        results[:attendees_app_badge_tasks_deleted] = aabt_length
      end

      if attendees_scavenger_hunt_item.destroy_all
        results[:attendees_scavenger_hunt_items_deleted] = ashi_length
      end

      if sessions_attendees.destroy_all
        results[:sessions_attendees_deleted] = sa_length
      end
    end

    if survey_data
      r_length = responses.length
      sr_length = survey_responses.length
      if survey_responses.destroy_all # destroys associated responses
        results[:responses_deleted]        = r_length
        results[:survey_responses_deleted] = sr_length
      end
    end
    results
  end

  def update_photo(image_file)
    event_file_type_id = EventFileType.where(name:'attendee_photo').first.id
    file_extension     = File.extname image_file.original_filename
    basename           = File.basename image_file.original_filename, file_extension
    # filename           = "#{basename.downcase.gsub(' ', '_')}#{Time.now.strftime('%Y%m%d%H%M%S')}#{file_extension}"
    filename           = "#{self.first_name}_#{self.last_name}_photo_#{Time.now().strftime('%Y%m%d%H%M%S')}#{file_extension}"

    event_file = photo_event_file_id ? EventFile.find(photo_event_file_id)
                                     : EventFile.new(event_id:event_id, event_file_type_id:event_file_type_id)

    # removed as this currently toggles 'online version' of photo file
    # update! photo_filename:filename
    cloud_storage_type_id = Event.find(event_id).cloud_storage_type_id
    unless cloud_storage_type_id.blank?
      cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
    end
    UploadEventFileImage.new(
      event_file:              event_file,
      image:                   image_file,
      target_path:             Rails.root.join('public', 'event_data', event_id.to_s, 'attendee_photos').to_path,
      new_filename:            filename,
      event_file_owner:        self,
      new_height:              400,
      new_width:               300,
      event_file_assoc_column: :photo_event_file_id,
      cloud_storage_type:      cloud_storage_type
    ).call
  end

  def event
    Event.find(event_id)
  end

  def publish_online(publishonline)
    if publishonline == "1" && !event_file_photo.blank? && !event.master_url.blank?
      update! photo_filename: event.master_url + event_file_photo.path
    else
      update! photo_filename: nil
    end
  end

  def update_account_code_if_blank
    self.update_column(:account_code,"ourcode" + self.id.to_s) if self.account_code.blank?
  end

  def full_name
    return "#{first_name} #{last_name}".strip
  end

  def generate_token
    self.token = loop do
      random_token = SecureRandom.urlsafe_base64(nil, false)
      break random_token unless Attendee.exists?(token: random_token)
    end
  end

  def confirmed?
    !!self.confirmed_at
  end

  def generate_confirmation_token
    self.confirmation_token = loop do
      confirmation_token = SecureRandom.urlsafe_base64(nil, false)
      break confirmation_token unless Attendee.exists?(confirmation_token: confirmation_token)
    end
  end

  # fiserv doesn't want it to be able to start with 0...?
  def generate_and_save_simple_numeric_password
      o = ('0'..'9').to_a
      event = Event.find_by(id: event_id)
      update!(password:  ('1'..'9').to_a.sample + (0...4).map { o[rand(o.length)] }.join) if event&.send_attendees_numeric_password?
      password
  end

  def generate_and_save_simple_password
      o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten # the alphabete
      update_column(:password,  (0...6).map { o[rand(o.length)] }.join)
      password
  end

  #Attendee.find(127394).send_app_messages([153715], "test message send_app_messages", "test message content send_app_messages")

  def send_app_messages(recipient_attendee_ids, message_title, message_content)
    offset              = Event.find(event_id).get_offset
    if offset == '-07:00'
      time = Time.zone.now.in_time_zone('Mountain Time (US & Canada)')
    else
      time = Time.zone.now.utc.localtime(offset)
    end
    sending_attendee_id = self.id

    if app_message_thread = AppMessageThread.create(event_id:event_id,title:message_title,active:1)
      app_message = AppMessage.create(event_id:event_id,app_message_thread_id:app_message_thread.id,attendee_id:sending_attendee_id,msg_time:time.strftime("%b #{time.day.ordinalize}, %I:%M %P"),content:message_content)
      AttendeesAppMessageThread.create(app_message_thread_id:app_message_thread.id,attendee_id:sending_attendee_id)
      recipient_attendee_ids.each do |recipient_attendee_id|
        AttendeesAppMessageThread.create(app_message_thread_id:app_message_thread.id,attendee_id:recipient_attendee_id)
      end
    end
  end

  # Attendee.find(127394).cms_send_app_messages("business discipline", "National Programs (NP)", [], "title", "message_content")

  def cms_send_app_messages(type, recipient_group_name, message_title, message_content)

    recipient_attendee_ids = []

    if type === "company"
      Attendee.where(event_id:event_id,company:recipient_group_name).pluck(:id).map { |id| recipient_attendee_ids << id }
    elsif type === "business_unit"
      Attendee.where(event_id:event_id,business_unit:recipient_group_name).pluck(:id).map { |id| recipient_attendee_ids << id }
    elsif type === "attendee"
      Attendee.where("event_id=? AND CONCAT(first_name, ' ', last_name)=?", event_id, recipient_group_name).pluck(:id).map { |id| recipient_attendee_ids << id }
    elsif type === "exhibitor"
      exhibitor = Exhibitor.where(event_id:event_id,company_name:recipient_group_name).first
      if exhibitor.attendees.length > 0
        exhibitor.attendees.pluck(:id).map { |id| recipient_attendee_ids << id }
      end
    elsif type === "incomplete_survey_attendees"
      health_check_done_attendee_ids = SurveyResponse.joins(:survey)
        .where("survey_responses.event_id = ? and surveys.survey_type_id = 7 and survey_responses.local_date = ?",
        event_id, recipient_group_name).pluck(:attendee_id)
      recipient_attendee_ids = Attendee.where.not(id: health_check_done_attendee_ids)
        .where(event_id: event_id).ids
    elsif type === ""
      # Attendee.where(event_id:event_id,company:recipient_group_name).pluck(:id).map { |id| recipient_attendee_ids << id }
    end
    # puts recipient_attendee_ids.inspect
    send_app_messages(recipient_attendee_ids, message_title, message_content) if recipient_attendee_ids.length > 0
  end

  def generate_and_send_ce_sessions_pdf_report(send_email, type, certificate_id=nil)

    def createDirectoryUnlessItExists(dirname)
      unless File.directory?(dirname) then FileUtils.mkdir_p(dirname); end
    end

    dirname = File.dirname(Rails.root.join('public','event_data', event_id.to_s,'generated_pdfs','pdf.pdf'))
    createDirectoryUnlessItExists(dirname)

    event_name = Event.find(event_id).name

    if event_name==='AVMA 2015'
      script_name = 'avma_attendee_ce_sessions.rb'
    elsif event_name==='ACVS 2015'
      script_name = 'acvs_attendee_ce_sessions.rb'
    elsif event_name==='MOTM 2016'
      script_name = 'adp_attendee_ce_sessions.rb'
    elsif event_id.to_s == "106" && type == ""
      script_name = "#{event_id}_ce_certificate.rb" # originally intended to be the general case for one pdf events
    else
      script_name = event_id.to_s + '_' + type.downcase + '.rb'
    end
    ## Below script also sends an email to the attendee
    if certificate_id
      certificate = CeCertificate.find certificate_id
    else
      cname = type.gsub('_', ' ')
      certificate = CeCertificate.find_by(event_id: event_id, name: cname)
      puts "No Certificate found with event_id #{event_id} and name: #{cname}" if certificate.blank?
      Rails::logger.debug "\n--------- import script output ---------\n\n No Certificate found with event_id #{event_id} and name: #{cname} \n------------------- \n" if certificate.blank?
  end
    json_data   = certificate&.json
    generate_pdf_cmd     = Rails.root.join('ek_scripts','pdf-generators',"#{script_name} \"#{event_id}\" \"#{id}\" \"#{send_email}\" \"#{type}\" #{json_data.to_json} #{certificate.mailer.to_json}")
   
    # @generate_pdf_result = `ROO_TMP='/tmp' ruby #{generate_pdf_cmd} 2>&1`
    pid = Process.spawn("ROO_TMP='/tmp' ruby #{generate_pdf_cmd} 2>&1")
    Process.detach pid
    # Rails::logger.debug "\n--------- import script output ---------\n\n #{@generate_pdf_result} \n------------------- \n"
  end

  def deleteTags(event_id, tag_type_id)
    tags_attendee = TagsAttendee.joins('LEFT JOIN tags ON tags_attendees.tag_id=tags.id')
                                .where('tags_attendees.attendee_id=? AND tags.tag_type_id=?',self.id,tag_type_id)

    tags_attendee.each do |tag_attendee|
      rows = Tag.where(id:tag_attendee.tag_id)
      if rows.length > 0
        leaf_tag = rows.first
      else
        leaf_tag = nil
      end
      curr_tag = leaf_tag
      #remove ancestor tags, if they have no child nodes and not referred to by other attendees
      while (curr_tag!=nil)
        if (Tag.where(parent_id:curr_tag.id,event_id:event_id).length==0 && TagsAttendee.where('tag_id=? AND attendee_id!=?',curr_tag.id,self.id).length==0) then
          parent_id = curr_tag.parent_id
          curr_tag.destroy()
          curr_tag = Tag.where(id:parent_id).first
        else
          curr_tag=nil #stop, hierarchy from here up is in use by another tag
        end
      end
      tag_attendee.destroy() #remove association record for leaf tag/attendee
    end
  end

  def update_tags tag_array, tag_type_name
    GenerateTagsForModel.new(self, tag_array, tag_type_name).call
    true # legacy implementation; if nothing was raised in the above func, always return true
  end

  def favourited_sessions_as_string
    sessions.map(&:session_code).join(',')
  end

  # Add slug to uniquely identify an attendee
  def set_slug
    loop do
      self.slug = SecureRandom.uuid
      break unless Attendee.where(slug: self.slug).exists?
    end
  end

  def check_and_set_username
    if self.username.blank?
      self.username = self.email
    end
  end

  def set_username
    self.username=self.email if self.username.blank? && !self.email.blank?
  end    

  def get_or_create_slug
    if self.slug.blank?
      self.set_slug
      self.save
    end
    self.slug
  end

  def self.paginated_data(page_filter = {page: 1, per_page: 30})
    offset((page_filter[:page].to_i - 1) * page_filter[:per_page].to_i).limit(page_filter[:per_page].to_i)
  end
  
  def get_photo_url
    unless self.event_file_photo.blank?
      ef = EventFile.find(photo_event_file_id)
      return ef.path if ef.cloud_storage_type_id.blank?
      ef.return_authenticated_url()['url']
    end
  end

  def member_type?
    atteendee_product = self.attendee_products.first
    if atteendee_product
      return atteendee_product.product.iid.gsub('_', ' ').upcase
    else
      return false
    end  
  end

  def send_password_mail_simple_reg
    model_name    = 'attendee'
    email_params  = {
      model:                    Attendee,
      event_id:                 self.event_id,
      model_id:                 self.id,
      email_type:               'send_password',
      active_time:              nil,
      deliver_later:            0,
      template_id:              nil
    }
    result = EmailsQueue.method("queue_email").call email_params
  end

end

# Attendee.with_scan_stats_for_event(170).first
