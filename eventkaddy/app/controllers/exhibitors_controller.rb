class ExhibitorsController < ApplicationController
  layout 'subevent_2013'
  load_and_authorize_resource

  require 'open-uri'

  def booth_owners_list
    render(:text =>
       Exhibitor
         .select('id, company_name')
         .where(event_id: params[:event_id])
         .reject {|e| BoothOwner.exists?(e.id) } # returns array where NOT true; ie rejected items
         .map {|e| e.id.to_s + ' ' + e.company_name + '<br>' }.join.html_safe
    )
  end

	def mobile_data
		@empty_data = "[]"
		if params[:event_id]
			Rails.cache.fetch "exhibitors-mobile-data-#{params[:event_id]}-#{params[:record_start_id]}" do
				@exhibitors = Exhibitor
          .select('exhibitors.id, logo, company_name, description, address_line1, address_line2, zip, state, city, country, email, phone, fax, url_web, url_twitter, url_facebook, url_linkedin, url_rss, message, location_mappings.name AS location_name, location_mappings.x AS location_x, location_mappings.y AS location_y, location_mappings.map_id AS map_id, location_mappings.booth_size_type_id AS booth_size_type_id, event_files.path AS file_url')
          .joins(' LEFT OUTER JOIN location_mappings ON location_mappings.id=exhibitors.location_mapping_id LEFT OUTER JOIN event_files ON exhibitors.logo_event_file_id=event_files.id')
          .where("exhibitors.event_id= ? AND exhibitors.id > ?", params[:event_id], params[:record_start_id])
          .order('exhibitors.id ASC')
          .limit(125)
          .to_json
			end
			@exhibitors = Rails.cache.read "exhibitors-mobile-data-#{params[:event_id]}-#{params[:record_start_id]}"
			if JSON.parse(@exhibitors).length > 0
				render :json => @exhibitors, :callback => params[:callback]
			else
				render :json => @empty_data, :callback => params[:callback]
			end
		end
	end

	def mobile_data_no_limit
		@empty_data = "[]"
		if params[:event_id]
      @exhibitors = Exhibitor
        .select('exhibitors.id, logo, company_name, description, address_line1, address_line2, zip, state, city, country, email, phone, fax, url_web, url_twitter, url_facebook, url_linkedin, url_rss, message, location_mappings.name AS location_name, location_mappings.x AS location_x, location_mappings.y AS location_y, location_mappings.map_id AS map_id, location_mappings.booth_size_type_id AS booth_size_type_id, event_files.path AS file_url')
        .joins(' LEFT OUTER JOIN location_mappings ON location_mappings.id=exhibitors.location_mapping_id LEFT OUTER JOIN event_files ON exhibitors.logo_event_file_id=event_files.id')
        .where("exhibitors.event_id= ?", params[:event_id])
        .order('exhibitors.id ASC')
        .to_json
			if JSON.parse(@exhibitors).length > 0
				render :json => @exhibitors, :callback => params[:callback]
			else
				render :json => @empty_data, :callback => params[:callback]
			end
		end
	end

	def mobile_data_exhibitor_leaf_tags
		@empty_data = "[]"
		if params[:event_id] && params[:record_start_id]
			@tags = Tag
        .select('tags.*, tag_types.name AS type_name, exhibitors.id AS exhibitor_id, tags_exhibitors.id AS teid')
        .joins(' JOIN tag_types ON tags.tag_type_id=tag_types.id LEFT OUTER JOIN tags_exhibitors ON tags.id=tags_exhibitors.tag_id LEFT OUTER JOIN exhibitors ON tags_exhibitors.exhibitor_id=exhibitors.id ')
        .where("tag_types.name= ? AND tags.event_id= ? AND tags_exhibitors.id > ?",'exhibitor', params[:event_id], params[:record_start_id])
        .order('tags_exhibitors.id ASC')
        .limit(125)
			if @tags.length > 0
				Rails::logger.debug "tags exhibitors records returned"
				render :json => @tags.to_json, :callback => params[:callback]
			else
				Rails::logger.debug "tags exhibitors empty"
				render :json => @empty_data, :callback => params[:callback]
			end
		end
	end

	def mobile_data_exhibitor_nonleaf_tags
		@empty_data = "[]"
		if params[:event_id] && params[:record_start_id]
			@tags = Tag
        .select('tags.*, tag_types.name AS type_name')
        .joins(' JOIN tag_types ON tags.tag_type_id=tag_types.id ')
        .where("tags.event_id= ? AND tags.leaf=? AND tag_types.name= ? AND tags.id > ?", params[:event_id],'0','exhibitor', params[:record_start_id])
        .order('tags.id ASC')
        .limit(125)
			if @tags.length > 0
				Rails::logger.debug "tags exhibitors records returned"
				render :json => @tags.to_json, :callback => params[:callback]
			else
				Rails::logger.debug "tags exhibitors empty"
				render :json => @empty_data, :callback => params[:callback]
			end
		end
	end

  def index
    if session[:event_id]
      @exhibitors = Exhibitor
        .select('exhibitors.*, location_mappings.name AS location_name')
        .joins('LEFT OUTER JOIN location_mappings ON location_mappings.id=exhibitors.location_mapping_id')
        .where("exhibitors.event_id= ?", session[:event_id])
        .order('exhibitors.id DESC')
      respond_to do |format|
        format.html
        format.xml  { render :xml => @exhibitors }
        format.json { render :json => @exhibitors.to_json, :callback => params[:callback] } #render :json => @exhibitors }
      end
    else
      redirect_to "/home/session_error"
    end
  end

  def show
    @exhibitor         = Exhibitor.find(params[:id])
    @coupons           = Coupon.where("exhibitor_id= ?", params[:id])
    @enhanced_listings = EnhancedListing.where("exhibitor_id= ?", params[:id])
    @exhibitor_links   = ExhibitorLink.where("exhibitor_id= ?", params[:id])
    respond_to do |format|
      format.html
      format.xml  { render :xml => @exhibitor }
      format.json { render :json => @exhibitor.to_json, :callback => params[:callback] }
    end
  end

  def new
    @exhibitor         = Exhibitor.new
    @room_mapping_type = LocationMappingType.where(type_name:'Booth').first.id
    @location_mappings = LocationMapping.where("location_mappings.mapping_type= ? AND event_id= ?",@room_mapping_type, session[:event_id]).order('location_mappings.name ASC')
    respond_to do |format|
      format.html
      format.xml  { render :xml => @exhibitor }
    end
  end

  def edit
    @exhibitor         = Exhibitor.find(params[:id])
    @room_mapping_type = LocationMappingType.where(type_name:'Booth').first.id
    @location_mappings = LocationMapping.where("location_mappings.mapping_type=? AND event_id=?",@room_mapping_type, session[:event_id]).order('location_mappings.name ASC')
  end

  def create
    params[:exhibitor][:event_id] = session[:event_id]
    @exhibitor = Exhibitor.new(exhibitor_params)
    @exhibitor.updateLogo(params)
    params[:exhibitor][:logo] = params[:online_url] == '1' ? @exhibitor.online_url : nil
    respond_to do |format|
      if @exhibitor.save!
        format.html { redirect_to(@exhibitor, :notice => 'Exhibitor was successfully created.') }
        format.xml  { render :xml => @exhibitor, :status => :created, :location => @exhibitor }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @exhibitor.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @exhibitor = Exhibitor.find(params[:id])
    @exhibitor.updateLogo(params)
    params[:exhibitor][:logo] = params[:online_url] == '1' ? @exhibitor.online_url : nil
    if params[:exhibitor][:staffs].present?
      staffs = {
        discount_staff_count: 0,
        complimentary_staff_count: 0
		  }
      staffs[:discount_staff_count] =  params[:exhibitor][:staffs]["discount_staff_count"].to_i
      staffs[:complimentary_staff_count] =  params[:exhibitor][:staffs]["complimentary_staff_count"].to_i
      @exhibitor.staffs = staffs.as_json
    end
    respond_to do |format|
      if @exhibitor.update!(exhibitor_params)
        format.html { redirect_to(@exhibitor, :notice => 'Exhibitor was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @exhibitor.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @exhibitor = Exhibitor.find params[:id]
    @exhibitor.destroy
    respond_to do |format|
      format.html { redirect_to(exhibitors_url) }
      format.xml  { head :ok }
    end
  end

	def exhibitor_tags
    @exhibitor = Exhibitor.find(params[:id])
    @tagType   = TagType.where(name:params[:tag_type_name])[0]
    @tags_exhibitor = TagsExhibitor
      .select('exhibitor_id, tag_id, tags.parent_id AS tag_parent_id, tags.name AS tag_name')
      .joins(' JOIN tags ON tags_exhibitors.tag_id=tags.id')
      .where('exhibitor_id=? AND tags.tag_type_id=?', @exhibitor.id, @tagType.id)
    @tag_groups = []
    @tags_exhibitor.each_with_index do |tag_exhibitor, i|
      @tag_groups[i] = []
      @tag_groups[i] << tag_exhibitor.tag_name
      parent_id = tag_exhibitor.tag_parent_id #acquired from above table join
      while parent_id!=0
        tag = Tag.where(event_id:session[:event_id], id:parent_id)
        if tag.length==1
          @tag_groups[i] << tag[0].name
          parent_id = tag[0].parent_id
        else
          parent_id=0
        end
      end
      @tag_groups[i].reverse! #reverse the order, as we followed the tag tree from leaf to root
      @tag_groups[i] << '' << '' << ''
    end
    for i in @tag_groups.length..(@tag_groups.length+4)
      @tag_groups[i] = []
      for j in 0..4
        @tag_groups[i] << ''
      end
    end
    respond_to do |format|
      format.html {  render action:"exhibitor_tags"  }
    end
	end

	def update_exhibitor_tags
		@exhibitor    = Exhibitor.find(params[:id])
		tag_type_name = TagType.find(params[:tag_type_id]).name
		tag_groups    = Tag.assemble_tag_array params
		respond_to do |format|
		  if @exhibitor.update_tags tag_groups, tag_type_name
		    format.html { redirect_to("/exhibitors/#{@exhibitor.id}/#{tag_type_name}/exhibitor_tags/", :notice => "#{tag_type_name.capitalize} tags successfully updated.") }
		  else
		    format.html { redirect_to("/exhibitors/#{@exhibitor.id}/#{tag_type_name}/exhibitor_tags/", :notice => "#{tag_type_name.capitalize} tags could not be updated.") }
		  end
		end
	end

	def tags_autocomplete
		if params[:term]
			@tags = Tag.find(:all, :conditions => ['name LIKE ? AND event_id=?', "%#{params[:term]}%", session[:event_id]])
		else
			@tags = Tag.where(event_id:session[:event_id])
		end
		respond_to do |format|
			format.json { render :json => @tags.to_json }
		end
	end

  def bulk_set_exhibitors_photos_to_online
    master_url = Event.find(session[:event_id]).master_url
    count = 0

    raise "This event's master url is not set, and the action could not be performed." if master_url.blank?

    #Removes the master url only returns the path(for details check speakers#bulk_set_speakers_photos_online)
    def clean_hack_for_exhibitor_photos path, master_url
      if path.match master_url
        path.split(master_url).last
      else
        path
      end
    end

    Exhibitor.where("event_id = ? and logo_event_file_id is not NULL", session[:event_id])
      .find_each { |exhibitor| next unless exhibitor.event_file  # in case id is set but record is lost
        count += 1
        full_url = master_url + clean_hack_for_exhibitor_photos(
          exhibitor.event_file.path, master_url
        )
        exhibitor.update! photo_filename: full_url
      }
    redirect_to exhibitors_path, notice: "#{count} exhibitors photos set to online."

  end

  def purchase_history
    @exhibitor         = Exhibitor.find(params[:id])
    @orders            = @exhibitor.user.orders.includes(:order_items, [transaction_detail: :mode_of_payment]).where(mode_of_payment: {event_id: session[:event_id]})
  end

  def files
    @exhibitor         = Exhibitor.find(params[:exhibitor_id])
    event_file_type    = EventFileType.where(name: "exhibitor_portal_file").first
    @extra_event_files = EventFile.where(
                          event_id: session[:event_id],
                          event_file_type_id: event_file_type.id
                        )

    event_file_type_pdf_upload = EventFileType.where(name:'exhibitor_pdf_upload').first
    @pdf_files                 = EventFile.where(
                                event_id: @exhibitor.event_id,
                                event_file_type_id: event_file_type_pdf_upload.id
                              )
  end

  private

  def exhibitor_params
    params[:exhibitor][:sponsor_level_type_id] = params[:exhibitor][:is_sponsor] == "1" ? params[:exhibitor][:sponsor_level_type_id] : ""
    params.require(:exhibitor).permit(:location_mapping_id, :url_tiktok, :event_id, :unpublished, :user_id, :logo_event_file_id, :sponsor_level_type_id,
      :company_name, :description, :logo, :address_line1, :address_line2, :city, :zip, :state, :country, :email, :phone, :fax, :url_web, :url_twitter,
      :url_facebook, :url_linkedin, :url_rss, :message, :is_sponsor, :contact_name, :contact_title, :toll_free, :unsubscribed, :token, :custom_fields,
      :tags_safeguard, :exhibitor_code, :diy_uploaded_location_name, :diy_uploaded_tagsets, :url_video, :url_instagram, :url_youtube, :contact_name_two,
      :contact_title_two, :contact_email_two, :contact_mobile_two, :custom_content, :welcome_chat, :enable_chat, :unavailable_chat, :contact_email, staffs: [:discount_staff_count, :complimentary_staff_count, :lead_retrieval_count])
  end

end
