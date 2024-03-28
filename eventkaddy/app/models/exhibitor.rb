class Exhibitor < ApplicationRecord

  include Magick

  serialize :staffs, JSON
  has_many :exhibitor_recommendations
  has_many :exhibitor_staffs, dependent: :destroy

  belongs_to :event
  belongs_to :sponsor_level_type, :optional => true
  has_one :sponsor_specification, :dependent => :destroy
  has_many :enhanced_listings, :dependent => :destroy
  has_many :exhibitor_files, :dependent => :destroy
  belongs_to :location_mapping, :optional => true
  belongs_to :event_file, :foreign_key => 'logo_event_file_id', optional: true
  belongs_to :background_image_file, :foreign_key => 'background_image', :class_name => "EventFile", optional: true
  belongs_to :user, :foreign_key => 'user_id', optional: true
  has_many :tags_exhibitors, :dependent => :destroy
  has_many :tags, :through => :tags_exhibitors
  has_many :sessions_sponsors, :dependent => :destroy, :foreign_key => 'sponsor_id'
  has_many :sessions, :through => :sessions_sponsors
  has_many :booth_owners, :dependent => :destroy
  has_many :attendees, :through => :booth_owners
  has_many :exhibitor_products, :dependent => :destroy
  has_many :attendee_scans, :dependent => :destroy
  has_many :exhibitor_stickers, dependent: :destroy
  before_create :generate_token
  before_save :url_check
  before_save :update_event_sponsor_level_types
  before_validation :set_default_staffs, on: :create

  attr_accessor :event_file_portal_logo
  attr_accessor :company

  def event_file_portal_logo=(value)
      @event_file_portal_logo = value
  end

  def generate_and_save_simple_password
    o        = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten # the alphabete
    password = (0...6).map { o[rand(o.length)] }.join

    User.first_or_create_for_exhibitor self, password
    password
  end

  def update_booth_owners account_codes
    result = { errors: [] }
    attendees         = Attendee.where(account_code: account_codes, event_id: event_id)
    exhibitor_type_id = AttendeeType.where(name:'Exhibitor').first.id

    account_codes.each do |ac|
      attendee = attendees.find {|a| a.account_code == ac }
      if attendee
        attendee.update! attendee_type_id: exhibitor_type_id
        BoothOwner.where(exhibitor_id: id, attendee_id: attendee.id).first_or_create
        BoothOwner.where('exhibitor_id != ? AND attendee_id=?', id, attendee.id).delete_all
      else
        result[:errors] << "Attendee with account_code #{ac} does not exist."
      end
    end

    # remove associations no longer desired
    if attendees.length > 0
      BoothOwner.
        where(exhibitor_id: id).
        where('attendee_id NOT IN (?)', attendees.map(&:id)).
        delete_all
    else # NOT IN (NULL) would fail, so just delete all if no account codes
      BoothOwner.where(exhibitor_id: id).delete_all
    end
    return result
  end

  def location_name
    location_mapping && location_mapping.name
  end

  def logo_path
    event_file && event_file.path
  end

  def url_check
    url_web.prepend 'http://' unless url_web.blank? || url_web =~ /\A#{URI::regexp(['http', 'https'])}\z/
    url_twitter.prepend 'http://' unless url_twitter.blank? || url_twitter =~ /\A#{URI::regexp(['http', 'https'])}\z/
    url_facebook.prepend 'http://' unless url_facebook.blank? || url_facebook =~ /\A#{URI::regexp(['http', 'https'])}\z/
    url_linkedin.prepend 'http://' unless url_linkedin.blank? || url_linkedin =~ /\A#{URI::regexp(['http', 'https'])}\z/
    url_rss.prepend 'http://' unless url_rss.blank? || url_rss =~ /\A#{URI::regexp(['http', 'https'])}\z/
  end

  def event_map
    location_mapping.event_map
  end

  def online_url
    event.cms_url + event_file.path if event_file
  end

  def online_logo?
    !logo.nil? && !!logo.match(/^http/)
  end

  # purely to fix different naming convention of other models for use with
  # upload_event_file_image service
  def online_url_column
    logo
  end

  def online_url_column=(string)
    update! logo: string
  end

  def update_tags tag_array, tag_type_name
    GenerateTagsForModel.new(self, tag_array, tag_type_name).call
    true # legacy implementation; if nothing was raised in the above func, always return true
  end

  # s3 updated
  def updateLogo(params)
    if params[:portal_logo_file]!=nil

      uploaded_io  = params[:portal_logo_file]
      file_ext     = File.extname uploaded_io.original_filename
      new_filename = "#{self.event_id}_exhibitor_logo_photo_#{Time.now().strftime('%Y%m%d%H%M%S')}#{file_ext}"
      target_path  = Rails.root.join('public','event_data', self.event_id.to_s,'exhibitor_logos').to_path
			event_file_type_id = EventFileType.where(name:"exhibitor_logo").first.id
      event_file         = self.event_file_portal_logo.blank? ?
                           EventFile.new(event_id:self.event_id, event_file_type_id:event_file_type_id) :
                           self.event_file_portal_logo

      cloud_storage_type_id   = Event.find(self.event_id).cloud_storage_type_id
      cloud_storage_type      = nil
      unless cloud_storage_type_id.blank?
        cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
      end

      UploadEventFileImage.new(
        event_file:              event_file,
        image:                   uploaded_io,
        target_path:             target_path,
        new_filename:            new_filename,
        event_file_owner: 			 self,
        event_file_assoc_column: :logo_event_file_id,
        cloud_storage_type:      cloud_storage_type,
        new_height:              400,
        new_width:               400
      ).call
    end
  end

  def generate_token
    self.token = loop do
      random_token = SecureRandom.urlsafe_base64(nil, false)
      break random_token unless Exhibitor.exists?(token: random_token)
    end
  end

  def tags_string
    exhibitor_tags = ''

    tagType = TagType.where(name:"exhibitor").first

    #find all the existing tag groups
    tags_exhibitor = TagsExhibitor.
      select('exhibitor_id,tag_id,tags.parent_id AS tag_parent_id,tags.name AS tag_name').
      joins('JOIN tags ON tags_exhibitors.tag_id=tags.id').
      where('exhibitor_id=? AND tags.tag_type_id=?', id, tagType.id)

    tag_groups = []

    tags_exhibitor.each_with_index do |tag_exhibitor, i|

      tag_groups[i] = []

      #add leaf tag
      tag_groups[i] << tag_exhibitor.tag_name
      parent_id = tag_exhibitor.tag_parent_id #acquired from above table join

      #add ancestor tags, if any
      while parent_id!=0
        tag = Tag.where( event_id:event_id, id:parent_id )
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
            exhibitor_tags += "#{tag}||"
          else
            exhibitor_tags += "#{tag}"
          end
        end
        unless (i+1)===tag_groups.length
          exhibitor_tags += "^^"
        end
      end
    end
    exhibitor_tags
  end

  def exhibitor_file_strings
    exhibitor_file_urls      = ''
    exhibitor_file_titles    = ''
    exhibitor_file_filetypes = ''

    exhibitor_files.each_with_index do |file, i|
      if i < ( exhibitor_files.length-1 )
        exhibitor_file_urls      += "#{file.event_file.name}, "
        exhibitor_file_titles    += "#{file.title}, "
        exhibitor_file_filetypes += "#{file.event_file.path.split('.').last}, "
      else
        exhibitor_file_urls      += "#{file.event_file.name}"
        exhibitor_file_titles    += "#{file.title}"
        exhibitor_file_filetypes += "#{file.event_file.path.split('.').last}"
      end
    end

    {
      exhibitor_file_urls:      exhibitor_file_urls,
      exhibitor_file_titles:    exhibitor_file_titles,
      exhibitor_file_filetypes: exhibitor_file_filetypes
    }
  end

  def self.portal_configs_init
    {
      videocontainer:{
        x:nil,
        y:nil,
        width:nil,
        height:nil,
        disabled:false
      },
      info:{
        x:nil,
        y:nil,
        width:nil,
        height:nil,
        disabled:false
      },
      files:{
        x:nil,
        y:nil,
        width:nil,
        height:nil,
        disabled:false
      },
      notes:{
        x:nil,
        y:nil,
        width:nil,
        height:nil,
        disabled:false
      },
      survey:{
        x:nil,
        y:nil,
        width:nil,
        height:nil,
        disabled:false
      },
      products:{
        x:nil,
        y:nil,
        width:nil,
        height:nil,
        disabled:false
      },
      links:{
        x:nil,
        y:nil,
        width:nil,
        height:nil,
        disabled:false
      },
      messages:{
        x:nil,
        y:nil,
        width:nil,
        height:nil,
        disabled:false
      },
      chat:{
        x:nil,
        y:nil,
        width:nil,
        height:nil,
        disabled:false
      },
      misc:{
        x:nil,
        y:nil,
        width:nil,
        height:nil,
        disabled:false
      },
      booking:{
        x:nil,
        y:nil,
        width:nil,
        height:nil,
        disabled:false
      },
      logo:{
        x: nil,
        y: nil,
        width: nil,
        height:nil,
        disabled:false
      }
    }
  end

  def merge_portal_configs configs
    portal_config = self.portal_configs || Exhibitor.portal_configs_init.as_json
    configs.each do |window,obj|
      !portal_config[window] && (portal_config[window]={})
      obj.each do |key,val|
        portal_config[window][key] = val
      end
    end
    self.portal_configs = portal_config
  end

  def update_event_sponsor_level_types
    EventSponsorLevelType.where(event_id: self.event_id, sponsor_level_type_id: self.sponsor_level_type_id).first_or_create
  end

  def set_location_mapping_after_purchase cart
    booth_item = cart.cart_items.find_by(item_type: 'LocationMapping')
    if booth_item && booth_item.item
      self.location_mapping = booth_item.item
      self.save
      booth_item.item.locked_by = nil
      booth_item.item.locked_at = nil
      booth_item.item.save
    end
  end

  def set_sponsor_level_type_after_purchase cart
    booth_items = cart.cart_items.where(item_type: 'SponsorLevelType')
    booth_items.each do |item|
      ExhibitorSponsorLevelType.find_or_create_by(exhibitor: self, sponsor_level_type: item.item)
    end
  end

  def decrease_one_complimentary_staff
    staffs = {
			discount_staff_count: self.staffs["discount_staff_count"],
			complimentary_staff_count: self.staffs["complimentary_staff_count"]
		}
    if self.staffs["complimentary_staff_count"] >= 1
      staffs[:complimentary_staff_count] = staffs[:complimentary_staff_count] - 1
    end
    staffs
  end

  private
  def set_default_staffs
    self.staffs ||= {
      discount_staff_count: 0,
      complimentary_staff_count: 0,
      lead_retrieval_count: 0
    }
  end
end
