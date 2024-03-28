class HomeButton < ApplicationRecord

	include ListItem
	extend ListItem

	include Magick

  # attr_accessible :event_file_id, :event_id, :icon_button_name, :name, :position, :enabled, :home_button_type_id, :external_link, :survey_id, :hide_on_mobile_site, :attendee_type_id
  attr_accessor :daily_survey_id

  belongs_to :home_button_type
  has_many   :custom_lists, :dependent => :destroy
  belongs_to :event_file,   :dependent => :destroy
  belongs_to :pdf_event_file, :foreign_key => 'pdf_event_file_id', :class_name => "EventFile", :dependent => :destroy, :optional => true

  validates_presence_of :home_button_type, :event_id, :name, :event_file_id
  validates_presence_of :external_link, if: -> { self.home_button_type.name==='External Link' }

  def type_name
    home_button_type.name
  end

  def custom_list?
    type_name == "Custom List"
  end

  def ce_info_custom_list?
    custom_list? && custom_lists.first.custom_list_type.name == 'CE Info'
  end
  def createAssociatedCustomListAndCustomListType custom_list_type_name=false
    # not sure where custom_list_type actually gets used in our apps;
    # but I will put it as always "user_made" only to distinguish a
    # usermade type with the same name as a non-usermade one. Which is 
    # to say, if we ever wanted to do some custom code based on type,
    # we can determine if it's based on a user_made home_button
    type_name = custom_list_type_name || name
    custom_list_type = CustomListType.where(name: type_name, user_made: true).first_or_create 
    CustomList.create(home_button_id:      id,
                      event_id:            event_id,
                      image_event_file_id: event_file_id,
                      name:                name,
                      custom_list_type_id: custom_list_type.id)
  end

  def createHomeButtonsCustomListsAndEventFileRows(event_id)

    # -- create the directory for home buttons and move default images there --

    Dir.mkdir(Rails.root.join('public', 'event_data', event_id.to_s),0755) unless File.directory?(Rails.root.join('public', 'event_data', event_id.to_s))
    Dir.mkdir(Rails.root.join('public', 'event_data', event_id.to_s,'home_button_group_images'),0755) unless File.directory?(Rails.root.join('public', 'event_data', event_id.to_s,'home_button_group_images'))

    File.chmod(0777,Rails.root.join('public', 'event_data', event_id.to_s))
    File.chmod(0777,Rails.root.join('public', 'event_data', event_id.to_s,'home_button_group_images'))

    src       = Rails.root.join('public', 'defaults','home_button_group_images/*')
    dst       = Rails.root.join('public', 'event_data', event_id.to_s,'home_button_group_images/')
    cp_result = `cp #{src} #{dst}`

		filenames_array             = []
		filenames_custom_list_array = []
		event_file_type_id          = EventFileType.where(name:"home_button_icon").first.id

    HomeButtonType.where(standard:true).each do |hbt|
    	filenames_array << hbt.name.downcase.gsub(" ", "_") + ".png" #unless hbt.name==="Custom List" || hbt.name==="External Link"
    end

    CustomListType.where(user_made:false).each do |clt|
    	filenames_custom_list_array << clt.name.downcase.gsub(" ", "_") + ".png"
    end

    # puts filenames_array
    # puts filenames_custom_list_array

    ## Create Home Buttons that are not Custom Lists
    filenames_array.each_with_index do |name, index|

      event_file = EventFile.create(
        event_id:           event_id,
        name:               name,
        mime_type:          "image/png",
        path:               "/event_data/#{event_id}/home_button_group_images/#{name}",
        event_file_type_id: event_file_type_id)

      HomeButton.create(
        event_id:         event_id,
        event_file_id:    event_file.id,
        name:             name.gsub(".png", "").gsub("_"," ").capitalize,
        icon_button_name: name,
        position:         index+1,
        enabled:          true,
        home_button_type_id: HomeButtonType.where(name:name.gsub(".png", "").gsub("_"," ").capitalize).first.id)
    end

    ## Create Home Buttons with Custom Lists and a few default items
    filenames_custom_list_array.each_with_index do |name, index|
      event_file = EventFile.create(
        event_id:           event_id,
        name:               name,
        mime_type:          "image/png",
        path:               "/event_data/#{event_id}/home_button_group_images/#{name}",
        event_file_type_id: event_file_type_id)

      home_button = HomeButton.create(
        event_id:         event_id,
        event_file_id:    event_file.id,
        name:             name.gsub(".png", "").gsub("_"," ").capitalize,
        icon_button_name: name,
        position:         index + filenames_array.length,
        enabled:          true,
        home_button_type_id: HomeButtonType.where(name:"Custom List").first.id)

      custom_list = CustomList.create(
        event_id:            event_id,
        home_button_id:      home_button.id,
        image_event_file_id: event_file.id,
        name:                name.gsub(".png", "").gsub("_"," ").capitalize,
        custom_list_type_id: CustomListType.where(name:name.gsub(".png", "").gsub("_"," ").capitalize).first.id)

      (1..3).each do |j|
        CustomListItem.create(
          event_id:       event_id,
          custom_list_id: custom_list.id,
          title:          "#{name.gsub(".png", "").gsub("_"," ").capitalize} #{j}",
          content:        "#{name.gsub(".png", "").gsub("_"," ").capitalize} Item #{j}",
          position:       j)
      end

    end
  end
  # s3 updated
	def uploadIcon(params,event_id)

		if (params[:image_file]!=nil) then
			uploaded_io             = params[:image_file]
			event_file_type_id      = EventFileType.where(name:"home_button_icon").first.id
      icon_button_name        = uploaded_io.original_filename if icon_button_name.blank?
			file_extension          = File.extname uploaded_io.original_filename
			event_file 							= event_file_id ? EventFile.find(event_file_id)
															: EventFile.new(event_id:event_id,event_file_type_id:event_file_type_id)
			target_path 						= Rails.root.join('public','event_data', event_id.to_s,'home_button_group_images').to_path
			cloud_storage_type_id   = Event.find(event_id).cloud_storage_type_id
			cloud_storage_type      = nil
			unless cloud_storage_type_id.blank?
				cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
			end

			UploadEventFileImage.new(
				event_file:              event_file,
				image:                   uploaded_io,
				target_path:             target_path,
				new_filename:            icon_button_name,
				event_file_owner: 			 self,
				event_file_assoc_column: :event_file_id,
				cloud_storage_type:      cloud_storage_type
      ).call
      self.icon_button_name   = icon_button_name
		end
	end


  def uploadPdf(document, event_id)
    if document!=nil && document.size < 150000000 && document.size > 0
      uploaded_io = document

      m = uploaded_io.original_filename.match(/.*(.pdf)$/i)
      if (m!=nil) then
        file_ext = m[1]
      else
        return 
      end

      new_filename = uploaded_io.original_filename

      new_filename.gsub!(/\s/,'_')
      new_filename.gsub!(/[^0-9A-Za-z.\-]/, '_')
      target_path             = Rails.root.join('public','event_data', event_id.to_s,'home_button_group_pdf')
      cloud_storage_type_id   = Event.find(event_id).cloud_storage_type_id
      cloud_storage_type      = nil
      unless cloud_storage_type_id.blank?
        cloud_storage_type    = CloudStorageType.find(cloud_storage_type_id)
      end

      event_file_type_id      = EventFileType.find_or_create_by(name: 'home_button_pdf').id
      event_file              = EventFile.create(event_id: event_id, event_file_type_id: event_file_type_id)
      UploadEventFile.new(
        event_file:              event_file,
        file:                    uploaded_io,
        target_path:             target_path,
        new_filename:            new_filename,
        event_file_owner:        self,
        event_file_assoc_column: :pdf_event_file_id,
        cloud_storage_type:      cloud_storage_type
      ).call
    end
    
  end
end
