class ExhibitorPortalsController < ApplicationController
  layout :set_layout

  # adds edit_tags and update_tags for preset tags
  include ExhibitorPortalsHelper
  include SimpleTagsRoutes

  #before_action in later versions of rails
  before_action :set_current_tab

  # this mainly exists to append @current_tab assignment to edit_tags
  def set_current_tab
    tab_default_name = case params[:action]
                       when 'landing'
                         'Welcome'
                       when 'show_exhibitordetails'
                         "Exhibitor Details"
                       when 'show_custom_content'
                         "Exhibitor Page Content"
                       when 'messages'
                         "Conference Messages"
                       when 'edit_tags'
                         'Exhibitor Tags'
                       when 'exhibitor_file'
                        'Exhibitor File'
                       # this lives in ExhibitorProductsController, so we have to call
                       # tab_by_event_and_default_name there instead
                       # when 'exhibitor_products'
                         # "Exhibitor Product"
                       end
    @current_tab = Tab.tab_by_event_and_default_name session[:event_id], tab_default_name, 'exhibitor'
  end

  def landing
    # !check_for_payment && (redirect_to :action => 'complete_purchase' and return)
  	@user          = current_user
    @event_setting = event_setting
  end

  def show_exhibitordetails
    check_payment_personalized_products
    @exhibitor     = get_exhibitor
    # @exhibitor && !check_for_payment && (redirect_to :action => 'complete_purchase' and return)
    @tag_groups    = get_tags(@exhibitor.id)
    @event_setting = event_setting
    @current_tab = get_current_tab("Exhibitor Details")
  end

  def update_exhibitordetails
    @exhibitor = get_exhibitor
    params[:exhibitor][:logo] = params[:online_url] == '1' ? @exhibitor.online_url : nil
    respond_to do |format|
      if @exhibitor.update!(exhibitor_params)
        @exhibitor.updateLogo(params)
        format.html { redirect_to("/exhibitor_portals/show_exhibitordetails", :notice => 'Exhibitor was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { redirect_to("/exhibitor_portals/show_exhibitordetails", :notice => 'Update error.') }
        format.xml  { render :xml => @exhibitor.errors, :status => :unprocessable_entity }
      end
    end
  end


  def edit_account
    @user = current_user
  end

  def update_account
    @user = current_user

    if params[:user][:password].blank?
      [:password,:password_confirmation,:current_password].collect{|p| params[:user].delete(p) }
    else
      @user.errors[:base] << "The password you entered is incorrect" unless @user.valid_password?(params[:user][:current_password])
    end

    respond_to do |format|
      if @user.errors[:base].empty? and @user.update!(user_params.except(:current_password))
        flash[:notice] = "Your account has been updated"
        sign_in(@user, bypass:true)
        format.json { render :json => @user.to_json, :status => 200 }
        format.xml  { head :ok }
        format.html { render :action => :landing }
      else
        format.json { render :text => "Could not update user", :status => :unprocessable_entity } #placeholder
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
        format.html { render :action => :edit_account, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:js, :xml, :html)
  end

  def product_preview
    @exhibitor     = get_exhibitor
    @tag_groups    = get_tags(@exhibitor.id)
    @event_setting = event_setting
    exhibitor_file_type_id = ExhibitorFileType.where(name:"exhibitor_document").first.id
    @exhibitor_files       = ExhibitorFile.where(exhibitor_id:@exhibitor.id,exhibitor_file_type_id:exhibitor_file_type_id)
  end

  def page_settings
    @exhibitor              = get_exhibitor
    @settings               = Setting.return_video_portal_booleans(session[:event_id])
    @portal_configs         = Exhibitor.portal_configs_init.merge( @exhibitor.portal_configs.blank? ? {} : @exhibitor.portal_configs.deep_symbolize_keys!)
    @portal_style_configs   = @exhibitor.portal_style_configs
  end

  def update_page_settings
    @exhibitor     = get_exhibitor
    @exhibitor.old_layout = page_settings_params[:old_layout]
    @exhibitor.merge_portal_configs page_settings_params[:portal_configs]
    @exhibitor.portal_style_configs = page_settings_params[:portal_style_configs]
    respond_to do |format|
      if @exhibitor.save!
        format.html { redirect_to("/exhibitor_portals/page_settings", :notice => 'Page settings was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { redirect_to("/exhibitor_portals/page_settings", :alert => @exhibitor.errors.full_messages) }
        format.xml  { render :xml => @exhibitor.errors, :status => :unprocessable_entity }
      end
    end
  end

  def show_custom_content # defunct
    @exhibitor     = get_exhibitor
    @event_setting = event_setting
  end

  def edit_custom_content
    unless params[:exhibitor_id].blank?
      session[:exhibitor_id_portal] = params[:exhibitor_id]
    end
    @exhibitor             = get_exhibitor
    # @exhibitor && !check_for_payment && (redirect_to :action => 'complete_purchase' and return)
    @event                 = Event.find(session[:event_id])
    exhibitor_file_type_id = ExhibitorFileType.where(name:"message_image").first.id
    @exhibitor_files       = ExhibitorFile.where(exhibitor_id:@exhibitor.id,exhibitor_file_type_id:exhibitor_file_type_id)
    @current_tab = get_current_tab("Exhibitor Page Content")
  end

  def update_custom_content
    if (params[:event_file]!='' && params[:event_file]!=nil) then
      @event_file              = EventFile.new
      @event_file.event_id     = session[:event_id]
      @event_file.exhibitor_id = get_exhibitor.id
      @event_file.exhibitorImage(params)
      respond_to do |format|
        if @event_file.save

          format.html {
            redirect_to('/exhibitor_portals/edit_custom_content', :notice => 'Content was successfully updated.')
          }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @event_file.errors, :status => :unprocessable_entity }
        end
      end
      return
    end

    @exhibitor         = get_exhibitor
    @exhibitor.custom_content = params[:exhibitor][:custom_content]

    respond_to do |format|
      if @exhibitor.save #update!(params[:notification])
        format.html { redirect_to('/exhibitor_portals/edit_custom_content', :notice => 'Content was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @exhibitor.errors, :status => :unprocessable_entity }
      end
    end
  end

  def ajax_data
    @exhibitor_id = get_exhibitor.id
    if ExhibitorFile.where(exhibitor_id:@exhibitor_id).length > 0
      render :plain => ExhibitorFile.where(exhibitor_id:@exhibitor_id).last.event_file.path
    end
  end

  def exhibitor_files
    check_payment_personalized_products
    # !check_for_payment && (redirect_to :action => 'complete_purchase' and return)
    @exhibitor       = get_exhibitor
    @exhibitor_id    = @exhibitor.id
    exhibitor_file_type_id = ExhibitorFileType.where(name:"exhibitor_document").first.id
    @exhibitor_files       = ExhibitorFile.where(exhibitor_id:@exhibitor.id,exhibitor_file_type_id:exhibitor_file_type_id)
    @exhibitor_portal = true
    @filetypes       = {"application/msword" => ".doc", "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => ".docx", "application/vnd.oasis.opendocument.spreadsheet" => ".ods", "application/pdf" => ".pdf", "text/plain" => ".txt", "application/rtf" => ".rtf", "application/vnd.ms-powerpoint" => ".ppt", "application/vnd.openxmlformats-officedocument.presentationml.presentation" => "pptx", "application/vnd.ms-excel" => ".xls", "application/xlsx" => ".xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" => ".xlsx", "video/quicktime" => ".mov", "video/mp4" => ".mp4", "audio/mpeg" => ".mp3", "application/octet-stream" => ".pez"}
    @current_tab = get_current_tab("Exhibitor Files")
  end

  def show_reports
    # !check_for_payment && (redirect_to :action => 'complete_purchase' and return)
    @exhibitor     = get_exhibitor
    @exhibitor_id    = @exhibitor.id
    setting_type_id = SettingType.find_by_name "cms_settings"
    setting         = Setting.where(event_id: session[:event_id], setting_type_id: setting_type_id).first
    @setting         = setting.json
    @reports = Attendee.find_by_sql(
      "SELECT at.id as attendee_id,
      at.first_name as first_name,
      at.last_name as last_name,
      at.company as company,
      at.email as email,
      sr.id AS sr_id,
      s.event_id AS s_event_id,
      at.business_phone,
      at.mobile_phone
     FROM attendees AS at
     LEFT JOIN survey_responses AS sr ON sr.attendee_id         = at.id
     LEFT JOIN surveys AS s ON s.id                             = sr.survey_id
     LEFT JOIN survey_exhibitors AS se ON se.survey_id          = s.id
     INNER JOIN responses ON responses.survey_response_id       = sr.id
     WHERE s.event_id='#{session[:event_id]}' AND s.survey_type_id=5 AND sr.exhibitor_id='#{@exhibitor_id}'
     GROUP BY at.id
     ORDER BY first_name")
    @reports
  end

  def show_responses_per_attendee
    @exhibitor       = get_exhibitor
    @exhibitor_id    = @exhibitor.id
    @attendee_id     = params[:attendee_id]
    @attendee        = Attendee.find @attendee_id
    setting_type_id = SettingType.find_by_name "cms_settings"
    setting         = Setting.where(event_id: session[:event_id], setting_type_id: setting_type_id).first
    @setting         = setting.json
    @surveys         = Survey.find_by_sql([
      "SELECT s.title AS survey_title,
        s.id AS survey_id,
        s.event_id,
        sr.id as survey_response_id,
        s.title
      FROM surveys AS s
      LEFT JOIN survey_responses AS sr ON sr.survey_id        = s.id
      WHERE s.event_id=? AND survey_type_id=5 AND sr.exhibitor_id=? AND sr.attendee_id=?
      GROUP BY sr.id
      ORDER BY s.id DESC", session[:event_id], @exhibitor_id, @attendee_id
    ])
  end

  def datatable_data
    ExhibitorReportsDatatable.new(
      params, session[:event_id], view_context
    ).datatable_data
  end

  def exhibitor_stickers
    check_payment_personalized_products
    @exhibitor = get_exhibitor
    @stickers = @exhibitor.exhibitor_stickers.where(event_id: session[:event_id]).order(z_index_position: :desc)
  end

  def create_sticker
    @exhibitor = get_exhibitor
    if sticker_params[:sticker_file]
      position = ExhibitorSticker.where(event_id: session[:event_id], exhibitor_id: @exhibitor.id).size
      @sticker = ExhibitorSticker.new(event_id: session[:event_id], exhibitor_id: @exhibitor.id,
        z_index_position: position, name: sticker_params[:name], link: sticker_params[:link])
      @sticker.save_and_update_sticker(sticker_params[:sticker_file])
      flash[:success] = "Sticker successfully created"
      redirect_back fallback_location: root_url
    else
      flash[:alert] = "No sticker image uploaded"
      redirect_back fallback_location: root_url
    end
  end

  def delete_sticker
    @exhibitor = get_exhibitor
    @sticker = ExhibitorSticker.find(params[:sticker_id])
    root_path = Rails.root.join('public')

    #remove the image file from the server
    FileUtils.rm(root_path.to_path + @sticker.event_file.path) if File.file? root_path.to_path + @sticker.event_file.path
    @sticker.event_file.destroy && @sticker.destroy
    remaining_stickers = ExhibitorSticker.where(event_id: session[:event_id], exhibitor_id: @exhibitor.id).order(:z_index_position)

    #update positions of remaining stickers
    remaining_stickers.each_with_index {|sticker, index| sticker.update! z_index_position: index}
    flash[:notice] = "The sticker has been deleted."
    redirect_back fallback_location: root_url
  end

  def reposition_stickers
    new_positions = params[:json].values
    ExhibitorSticker.update_positions new_positions
    render json: {notice: "ok"}, statu: 200
  end

  def update_sticker
    @sticker = ExhibitorSticker.find(params[:sticker_id])
    if sticker_params[:sticker_file]
      #remove old image from storage
      old_image = Rails.root.join('public').to_path + @sticker.event_file.path
      FileUtils.rm old_image if File.file? old_image
      #update sticker record
      @sticker.name = sticker_params[:name]
      @sticker.link = sticker_params[:link]
      @sticker.save_and_update_sticker sticker_params[:sticker_file]
      flash[:notice] = "Sticker details and image has been updated"
      redirect_back fallback_location: root_url
    else
      @sticker.update! sticker_params
      flash[:notice] = "Sticker has been updated"
      redirect_back fallback_location: root_url
    end
  end

  def update_sticker_fixed_status
    @sticker = ExhibitorSticker.find(params[:sticker_id])
    @sticker.update! fixed_state: params[:state].eql?("true")
    render json: { notice: "success" }, status: 200
  end

  def mobile_app_preview
  end

  def mobile_app_content
    @exhibitor = get_exhibitor
    @ekm_settings = Setting.return_cordova_ekm_settings session[:event_id]
    @media_file = MediaFile.where(exhibitor_id: @exhibitor.id, event_id: session[:event_id]).order(:position).first
    respond_to { |format| format.html { render :layout => false } }
  end

  def my_orders
    @orders = current_user.orders.includes(:order_items, [transaction_detail: :mode_of_payment]).where(mode_of_payment: {event_id: session[:event_id]})
    @current_tab = get_current_tab("Orders")
  end

  def complete_purchase
  end

  def download_invoice
    transaction = Transaction.find_by(id: params[:transaction_id])
    def send_pdf(pdf)
        send_data pdf.render, type: "application/pdf"
    end

    def ensure_directory_exists(dirname)
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
    end

    def generate_pdf(transaction, settings)
      order       = Order.find_by(transaction_id: transaction.id)
      user        = order.user
      event       = Event.find_by(id: session[:event_id])

      header = "<b>Receipt</b>"
      payment_id = "Payment ID: #{transaction.external_payment_id}"
      date_of_payment = "Date Paid: #{transaction.updated_at.strftime("%B %d, %Y")}"
      event_name = event.name

      biller = "#{event.organization.name}
      #{event.organization.address_line1}
      #{event.organization.address_line2}
      #{event.organization.city}
      #{event.organization.zip}
      #{event.organization.country}
      #{event.organization.contact_mobile}"

      payee = "Bill To
      #{"#{user.first_name} #{user.last_name}".strip}
      #{user.email}
      "
      credits_array = []
      credits_array << ["Description","Qty","Unit Price","Amount"]
      order.order_items.each do |order_item|
        if order_item.item_type == 'LocationMapping'
          product_name = order_item.item.name
        elsif order_item.item_type == 'SponsorLevelType'
          product_name = order_item.item.sponsor_type
        elsif order_item.item_type == 'Product'
          product_name = order_item.item.name
          if order_item.discount_allocations.present?
            discount_allocation = order_item.discount_allocations.first
          end
        end

        if discount_allocation.present?
          if discount_allocation.discounted_count > 0
            credits_array << ['Discount passes', discount_allocation.discounted_count, "$" + order_item.item.member_price.to_s, "$" +  discount_allocation.discounted_amount.to_s ]
          end
          if discount_allocation.full_count > 0
            credits_array << ['Additional passes', discount_allocation.full_count, "$" + order_item.item.price.to_s, "$" +  discount_allocation.full_amount.to_s ]
          end
        else
          credits_array << [product_name, order_item.quantity, "$" + order_item.price.to_s, "$" + (order_item.price * order_item.quantity).to_s]
        end
      end


      paid_at_line = "<b>$#{transaction.amount} paid on #{date_of_payment}</b>"

      pdf           = Prawn::Document.new

      pdf.text      header, align: :left, size: 18, font: "Times-Roman", inline_format: true
      pdf.move_down 10
      pdf.text      payment_id
      pdf.move_down 2
      pdf.text      date_of_payment
      pdf.text_box  biller, inline_format: true, width: 510, at:[0,650]
      pdf.text_box  payee, inline_format: true, width: 510, at:[210,650]
      pdf.move_down 60
      pdf.text      paid_at_line, align: :left, size: 14, font: "Times-Roman", inline_format: true

      image_id = event.logo_event_file_id
      event_file = EventFile.find_by(id: image_id) rescue nil
      if event_file
        image = event_file.return_authenticated_url['url']
        pdf.image     open(image), position: :right, width:100, vposition: 0
      end

      pdf.table(credits_array, position: :center, column_widths:{0 => 250, 1 => 90, 2 => 90, 3 => 100}, cell_style: {size: 10, :inline_format => true }) do
        cells.padding = 10
        cells.borders = []
        row(0).borders = [:bottom]
        style(row(0), font_style: :bold)
      end

      if settings.transaction_tax_value.present?
        total_with_tax = (order.total.to_i * settings.transaction_tax_value.to_i)/100
        pdf.table([["#{settings.transaction_tax_name} #{settings.transaction_tax_value.to_i} % ", "$" + total_with_tax.to_s ]], position: :right, column_widths:{0 => 180, 1 => 107}, cell_style: {size: 10, :inline_format => true }) do
          cells.padding = 10
          cells.borders = []
          cells.border_lines = [:dotted]
          row(0).borders = [:bottom, :top]
        end
      end

      pdf.table([['SubTotal', "$" + transaction.amount.to_s]], position: :right, column_widths:{0 => 180, 1 => 107}, cell_style: {size: 10, :inline_format => true }) do
        cells.padding = 10
        cells.borders = []
        cells.border_lines = [:dotted]
        row(0).borders = [:bottom, :top]
      end

      pdf.table([['Total Paid', "$" + transaction.amount.to_s]], position: :right, column_widths:{0 => 180, 1 => 107}, cell_style: {size: 10, :inline_format => true }) do
        cells.padding = 10
        cells.border_lines = [:dotted]
        row(0).borders = [:bottom, :top]
      end

      filename = "Invoice Transaction Id #{transaction.id}.pdf"

      ensure_directory_exists File.dirname(Rails.root.join('public','event_data',event_id.to_s,'generated_pdfs',filename))

      pdf.render_file "./public/event_data/#{event_id}/generated_pdfs/#{filename}"
      "/event_data/#{event_id}/generated_pdfs/#{filename}"
    end

    settings = Setting.return_exhibitor_registration_portal_settings(session[:event_id])

    respond_to do |format|
      if transaction
        format.html {redirect_to(generate_pdf(transaction, settings)) }
      else
        format.html {redirect_to("/purchase_history")}
      end
    end
  end

  def products
    check_payment_personalized_products
    map_type   = MapType.find_by_map_type('Interactive Map')
    @event_map = EventMap.joins(location_mappings: :products).
                          find_by(map_type_id: map_type.id, event_id: session[:event_id])
    @cart      = Cart.find_or_create_by(user: current_user)
    @cart.update(status: 'on_product_select_page')
    @settings = Setting.return_exhibitor_registration_portal_settings(session[:event_id])
    product_category_ids = @settings.product_categories_ids
    @product_category_with_product = ProductCategory
                                      .joins(:products)
                                      .where(id: product_category_ids)
                                      .order(:order)
                                      .uniq
    @current_tab = get_current_tab("Product")
    @exhibitor   = current_user.exhibitors.where(event_id: session[:event_id]).first
    if @exhibitor.location_mapping_id.present?
      excluded_product_category = ProductCategory.where(event_id: 278, iid: ['exhibitor_booth', 'sponsorship_with_booth_selection', 'sponsorship_with_booth'])
      @product_category_with_product = @product_category_with_product - excluded_product_category
    end
  end

  def cart
    cart_id  = params[:cart_id]
    event_id = params[:event_id]
    @cart   = Cart.find cart_id

    @cart.status = 'on_cart_page'
    @cart.save

    exhibitor = current_user.exhibitors.where(event_id: event_id).first
    @settings = Setting.return_exhibitor_registration_portal_settings(event_id)

    if !@cart.cart_items.present?
      redirect_to "/exhibitor_portals/products", alert: 'Cart Items are unavailable' and return
    end

    booth_item = @cart.cart_items.find_by(item_type: 'LocationMapping')

    if exhibitor.location_mapping.present? && !booth_item.nil?
      redirect_to "/exhibitor_portals/products", alert: 'Can not buy multiple booth.' and return
    end

    if !booth_item.nil?
      if !booth_item&.item&.is_available?
        booth_item.delete
        redirect_to "/#{event_id}/exhibitor_registrations/cart/#{@cart.id}", notice: "Booth is not available" and return
      end
    end

    sponsorship_with_booth_selection_category = ProductCategory.find_by( iid: 'sponsorship_with_booth_selection', event_id: event_id )
    product_category_ids                      = @settings.product_categories_ids
    cart_items                                = @cart.cart_items.includes(:item).where(item_type: 'Product')
    category_ids                              = cart_items.map { |item| item.item.product_categories_id }.uniq

    if sponsorship_with_booth_selection_category && category_ids.include?(sponsorship_with_booth_selection_category.id)
      if booth_item.nil?
        redirect_to "/exhibitor_portals/products", notice: 'Kindly Select the Booth first.'
      end
    end

    @total = @cart.calculate_total_amount_v2(sponsorship_with_booth_selection_category, category_ids, exhibitor)
  end

  def create_order_cart
    event_id   = params[:event_id]
    cart_id    = params[:id]
    cart       = Cart.find cart_id
    user       = cart.user
    cart_items = cart.cart_items

    if !cart_items.present?
      redirect_to "/exhibitor_portals/products", notice: 'Cart is Empty.'
    end

    cart_items.each do |cart_item|
      if cart_item.item_type == 'LocationMapping'
        if !cart_item.item.is_available?
          redirect_to "/exhibitor_portals/products", notice: 'Booth is not available.'
          break;
          return
        end
      else
        check_availability = cart_item.item.available_qantity > 0
        if !check_availability
          notice = " product is unavailable. please remove #{cart_item.item.name} from cart"
          redirect_to "/exhibitor_portals/products", notice: notice
          break;
          return
        end
      end
    end

    created_order = user.create_order_for_exhibitor
    cart.status = 'on_payment_page'
    cart.save

    redirect_to "/#{params[:event_id]}/exhibitor_portals/payment/#{cart.id}/#{created_order.id}"
  end

  def exhibitor_payment_v2
    event_id = params[:event_id]
    cart_id  = params[:cart_id]
    @cart = Cart.find_by(id: cart_id)
    @cart.status = 'on_payment_page'
		@cart.save
    exhibitor = current_user.exhibitors.where(event_id: event_id).first
    @settings = Setting.return_exhibitor_registration_portal_settings(event_id)
    mode_of_payment_id = Transaction.payment_available?(@settings)
    if mode_of_payment_id.present?
      @mode_of_payment = ModeOfPayment.find_by(id: mode_of_payment_id)
      @transaction = Transaction.create(
        mode_of_payment: @mode_of_payment,
        transaction_status_type: TransactionStatusType.pending,
        cart: @cart
      )
      @total = 0

      booth_item = @cart.cart_items.find_by(item_type: 'LocationMapping')
      booth_item_bought_earlier = @cart.user.orders.flat_map { |order| order.order_items.select { |item| item.item_type == LocationMapping } }

      cart_items_product_ids          = @cart.cart_items.where( item_type: "Product" ).pluck(:item_id)
      products                        = Product.where( id: cart_items_product_ids )
      @category_ids                   = products.pluck( :product_categories_id )
      sponsorship_with_booth_category = ProductCategory.find_by( iid: 'sponsorship_with_booth', event_id: event_id )
      @sponsorship_with_booth_selection_category = ProductCategory.find_by( iid: 'sponsorship_with_booth_selection', event_id: event_id )



      if sponsorship_with_booth_category && @category_ids.include?(sponsorship_with_booth_category.id)
        sponsorship_with_booth_category_product = sponsorship_with_booth_category.products.where(id: cart_items_product_ids).first
        if !(sponsorship_with_booth_category_product && sponsorship_with_booth_category_product.available_qantity > 0)
          cart_item = @cart.cart_items.where(item_id: sponsorship_with_booth_category_product.id).first
          if cart_item.present?
            cart_item.delete
          end
          redirect_to "/exhibitor_portals/products", alert: 'Cart Items are unavailable' and return
        end
      elsif (@sponsorship_with_booth_selection_category && !booth_item)
        sponsorship_with_booth_selection_category_product = @sponsorship_with_booth_selection_category.products.where(id: cart_items_product_ids).first
        if !sponsorship_with_booth_selection_category_product.nil?
          redirect_to "/exhibitor_portals/products", alert: 'Booth not selected, please select the booth first.' and return
        end
      elsif booth_item
        booth = booth_item.item
        if ( booth.locked_by && booth.locked_by != @cart.user_id )
          redirect_to "/exhibitor_portals/products", alert: 'Booth has been currently locked IN' and return
        else
          booth.locked_by = @cart.user_id
          if booth.locked_at
            @timer = booth.locked_at + 10.minute
            if DateTime.now.utc > @timer
              booth.locked_by = nil
              booth.locked_at = nil
              booth.save
              redirect_to "/exhibitor_portals/products", alert: "Time's Up, reselect the booth and try again" and return
            end
          else
            BoothOwnerWorker.perform_in(600, booth.id)
            booth.locked_at = DateTime.now.utc
            booth.save
            @timer = booth.locked_at + 10.minute
          end
        end
      end

      @cart.cart_items.each do |cart_item|
        if cart_item.item_type == 'Product'
          if cart_item.item.product_category.iid == 'staff_members'
            @discount_allocation = DiscountAllocation.find_or_initialize_by(
              cart_item: cart_item,
              event_id: event_id,
              user_id: current_user.id
            )
						@discount_allocation.
						apply_discount(
							cart_item.quantity,
							exhibitor.staffs["complimentary_staff_count"],
							exhibitor.staffs["discount_staff_count"],
							cart_item.item.member_price,
							cart_item.item.price
						)
						@total = @total + @discount_allocation.amount
            @maximum_complimentary_staff = @discount_allocation.complimentary_count
            @maximum_discount_staff = @discount_allocation.discounted_count
          else
            @total = @total + (cart_item.item.price * cart_item.quantity )
          end
        elsif cart_item.item_type == "LocationMapping"
          if cart_item.discount_allocations.present? && !(@sponsorship_with_booth_selection_category && @category_ids.include?(@sponsorship_with_booth_selection_category.id))
            cart_item.discount_allocations.delete_all
          end
          if @sponsorship_with_booth_selection_category && @category_ids.include?(@sponsorship_with_booth_selection_category.id)
            discount_allocation_booth = DiscountAllocation.find_or_initialize_by(
              cart_item: cart_item,
              event_id: params[:event_id],
              user_id: @cart.user_id
            )
            discount_allocation_booth.apply_discount_booth(  cart_item.item.products.first.price )

            @total = @total + discount_allocation_booth.amount
          else
            @total = @total + (cart_item.item.products.first.price * cart_item.quantity )
          end
        else
          @total = @total + (cart_item.item.products.first.price * cart_item.quantity )
        end

      end
    end
  end

  def exhibitor_payment
    event_id = params[:event_id]
    order_id = params[:order_id]
    cart_id  = params[:cart_id]

    @cart = Cart.find_by(id: cart_id)
    @cart.status = 'on_payment_page'
		@cart.save

    @order = Order.find order_id
    exhibitor = current_user.exhibitors.where(event_id: event_id).first
    @settings = Setting.return_exhibitor_registration_portal_settings(event_id)
    mode_of_payment_id = Transaction.payment_available?(@settings)
    if !mode_of_payment_id.present?
			redirect_to "/exhibitor_portals/products", alert: 'Payment mode is not availabale right now.'
    end

    @mode_of_payment = ModeOfPayment.find_by(id: mode_of_payment_id)
		if @mode_of_payment.name == 'Stripe'
			@stripe_env = @mode_of_payment.client_key
		elsif @mode_of_payment.name == 'PayPal'
			@client_id = @mode_of_payment.client_key
		end

    location_mapping = @order.order_items.where(item_type: 'LocationMapping').first
    if location_mapping.present?
			booth_available = OrderItem.joins(:order).where(item_id: location_mapping.item_id).where(orders: {status: 'paid'})
		end

    if booth_available.present?
			location_mapping.delete
			redirect_to "/#{event_id}/exhibitor_portals/cart/#{cart.id}", alert: 'Booth is unavailable, please select another booth'
		end

    if location_mapping.present?
			if !location_mapping.item.is_available?
				if !location_mapping.item.locked_by == @cart.user_id
					redirect_to "/exhibitor_portals/products", notice: 'Booth is not available.'
				end
			end
		end

    sponsorship_with_booth_selection_category = ProductCategory.find_by( iid: 'sponsorship_with_booth_selection', event_id: event_id )
    product_category_ids                      = @settings.product_categories_ids
    cart_items                                = @cart.cart_items.includes(:item).where(item_type: 'Product')
    category_ids                              = cart_items.map { |item| item.item.product_categories_id }.uniq

    @total  = @order.calculate_total_order_amount_v2(sponsorship_with_booth_selection_category, category_ids, exhibitor)
    booth_item = location_mapping&.item
		if booth_item.present?
			if (booth_item.locked_by && booth_item.locked_by != @cart.user_id)
				redirect_to "/exhibitor_portals/products", alert: 'Booth has been currently locked IN'
			else
				booth_item.locked_by = @cart.user_id
				if booth_item.locked_at
					@timer = booth_item.locked_at + 10.minute
					if DateTime.now.utc > @timer
						booth_item.locked_by = nil
						booth_item.locked_at = nil
						booth_item.save
						redirect_to "/exhibitor_portals/products", alert: "Time's Up, reselect the booth and try again"
					end
				else
					BoothOwnerWorker.perform_in(600, booth_item.id)
					booth_item.locked_at = DateTime.now.utc
					booth_item.save
					@timer = booth_item.locked_at + 10.minute
				end
			end
		end
  end

  # PDF Management
  #GET
  def index_pdf
    @event_file_type = EventFileType.where(name:'exhibitor_pdf_upload').first
    @event_file_type2 = EventFileType.where(name:'exhibitor_pdf_no_sign').first
    @pdf_files = EventFile.where(event_id:session[:event_id],event_file_type_id:[@event_file_type.id,@event_file_type2.id])
    # @event_files = nil

    respond_to do |format|

      format.html { render:'index_pdf', layout:'subevent_2013'}
  end
  end

  # GET
  #create a new pdf
  def new_pdf
    @pdf = EventFile.new

    respond_to do |format|
      format.html { render:'new_pdf', layout:'subevent_2013'}
    end
  end

  def create_pdf
    @pdf          = EventFile.new(event_file_params)
    @pdf.event_id = session[:event_id]
    @pdf.uploadPdfUpdated(params, "exhibitor")
    @pdf.save()

    respond_to do |format|
      format.html { redirect_to('/exhibitor_portals/index_pdf', :notice => 'PDF successfully created') }
    end
  end

  def edit_pdf
    @pdf = EventFile.find(params[:id])
    @signed = @pdf.event_file_type.name.eql? "exhibitor_pdf_upload"

    respond_to do |format|
      format.html { render:'edit_pdf', layout:'subevent_2013' }
    end
  end

  def update_pdf
    @pdf = EventFile.find(params[:id])
    @pdf.uploadPdfUpdated(params, "exhibitor")

    respond_to do |format|
      if @pdf.update!(event_file_params)
        format.html { redirect_to('/exhibitor_portals/index_pdf', :notice => 'PDF was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit_pdf" }
        format.xml  { render :xml => @pdf.errors, :status => :unprocessable_entity }
      end
    end

  end

  def delete_pdf
    @pdf = EventFile.find(params[:id])
    @pdf.destroy

    respond_to do |format|
      format.html { redirect_to('/exhibitor_portals/index_pdf') }
    end
  end

  def download_pdf
    check_payment_personalized_products
    @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first

    exhibitor = get_exhibitor
    @exhibitor=exhibitor
    #retrieve existing pdfs
    @event_file_type = EventFileType.where(name:'exhibitor_pdf_upload').first
    @pdf_files = EventFile.where(event_id:exhibitor.event_id,event_file_type_id:@event_file_type.id)
    @event_file_type = EventFileType.where(name:'exhibitor_pdf_no_sign').first
    @info_pdf_files=EventFile.where(event_id:exhibitor.event_id,event_file_type_id:@event_file_type.id)

    @event_file_type = EventFileType.where(name: "exhibitor_portal_file").first
    @extra_event_files = EventFile.where(event_id:exhibitor.event_id,event_file_type_id:@event_file_type.id)
    @current_tab = get_current_tab("PDF Downloads")
  end

  def new_file
    @file = EventFile.new

    respond_to do |format|
      format.html { render:'new_file', layout:'subevent_2013'}
    end
  end

  def create_file
    @file           = EventFile.new(event_file_params)
    @file.event_id  = session[:event_id]
    @file.upload_file(params, "exhibitor")
    @file.save()
    respond_to do |format|
      format.html { redirect_to('/exhibitor_portals/files', :notice => 'PDF successfully created') }
    end
  end

  def edit_file
    @file = EventFile.find(params[:id])

    respond_to do |format|
      format.html { render:'edit_file', layout:'subevent_2013' }
    end
  end

  def update_file
    @file = EventFile.find(params[:id])
    @file.upload_file(params, "exhibitor")

    respond_to do |format|
      if @pdf.update!(event_file_params)
        format.html { redirect_to('/exhibitor_portals/index_pdf', :notice => 'File was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit_file" }
        format.xml  { render :xml => @pdf.errors, :status => :unprocessable_entity }
      end
    end
  end

  def files
    @event_file_type = EventFileType.where(name:'exhibitor_portal_file').first
    @files = EventFile
                  .where(
                    event_id:session[:event_id],
                    event_file_type_id: @event_file_type.id
                  )

  end

  private

  # 2017 thoughts: EventSetting was a very old attempt at doing
  # per event configuration. We would probably prefer switching over
  # to the settings table that uses json for this. Most of the columns
  # in event_settings refer to the speaker portal, which would probably
  # also like to be replaced.
  def event_setting
    EventSetting.where(event_id:session[:event_id]).first_or_create
  end

  def get_exhibitor
    if current_user.role? :exhibitor then
      if current_user.is_a_staff?
        es = ExhibitorStaff.find_by_user_id current_user.id
        return Exhibitor.find es.exhibitor_id
      else
        current_user.first_or_create_exhibitor( session[:event_id] )
      end
    elsif !session[:exhibitor_id_portal].blank?
      puts "test: #{session[:exhibitor_id_portal]}"
      Exhibitor.find(session[:exhibitor_id_portal])
    end
  end

  def check_payment_personalized_products
    if !(current_user.first_name.present? && current_user.last_name.present?)
      redirect_to "/users/#{current_user.id}/account"
      return
    end
    if current_user.role? :exhibitor
      exhibitor = current_user.exhibitors.where(event_id: session[:event_id]).first
      if exhibitor
        exhibitor_product = Product.where(exhibitor_id: exhibitor.id).first
        if exhibitor_product.present?
          order_item        = OrderItem.where( item_id: exhibitor_product.id ).first
          orders = Order.includes(:order_items).where(order_items: { item_id: exhibitor_product.id}, orders: { status: 'paid'})
          if !orders.present?
            cart      = Cart.find_or_create_by(user: current_user)
            cart.cart_items.find_or_create_by(item_id: exhibitor_product.id, item_type: "Product", quantity: 1)
            redirect_to "/#{session[:event_id]}/exhibitor_portals/cart/#{cart.id}"
            return
          end
        end
      end
    end
  end

  def get_tags(exhibitor_id)
    tag_type_id = TagType.where(name:'exhibitor')[0].id
    #find all the existing tag groups
    tags_exhibitor = TagsExhibitor.select('exhibitor_id,tag_id,tags.parent_id AS tag_parent_id,tags.name AS tag_name').joins('
      JOIN tags ON tags_exhibitors.tag_id=tags.id'
      ).where('exhibitor_id=? AND tags.tag_type_id=?', exhibitor_id, tag_type_id)

    tag_groups = []
    tags_exhibitor.each_with_index do |tag_exhibitor,i|

      tag_groups[i] = []

      #add leaf tag
      tag_groups[i] << tag_exhibitor.tag_name
      parent_id = tag_exhibitor.tag_parent_id #acquired from above table join

      #add ancestor tags, if any
      while (parent_id!=0)
        tag = Tag.where(event_id:session[:event_id],id:parent_id)
        if (tag.length==1) then
          tag_groups[i] << tag[0].name
          parent_id = tag[0].parent_id
        else
          parent_id=0
        end
      end

      tag_groups[i].reverse! #reverse the order, as we followed the tag tree from leaf to root
    end
    tag_groups
  end

  # for benefit of mixed in SimpleTagsRoutes
  def tag_type_name
    'exhibitor'
  end

  # for benefit of mixed in SimpleTagsRoutes
  def model_id
    get_exhibitor.id
  end

  def set_layout
    if current_user.role? :exhibitor then
      'exhibitorportal'
    else
      'subevent_2013'
    end
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation, :current_password)
  end

  def exhibitor_params
    params.require(:exhibitor).permit(:event_id, :logo, :company_name, :email, :message, :description,
      :url_web, :url_twitter, :url_facebook, :url_linkedin, :url_rss, :url_instagram, :url_youtube,
      :url_tiktok, :contact_name, :contact_title, :address_line1, :address_line2, :city, :state, :country,
      :zip, :phone, :fax, :contact_name_two, :contact_title_two, :contact_email_two, :contact_mobile_two, :contact_email)
  end

  def sticker_params
    params.require(:exhibitor_sticker).permit(:name, :link, :sticker_file)
  end

  def page_settings_params
    params.require(:exhibitor).permit(:old_layout, :portal_configs => {}, :portal_style_configs => {})
  end

  def event_file_params
    params.require(:event_file).permit(:event_id, :name, :size, :mime_type, :path, :event_file_type_id, :created_at, :updated_at, :exhibitor_id)
  end

  def get_current_tab(default_name)
    current_tab = Tab.tab_by_event_and_default_name session[:event_id], default_name, 'exhibitor'
  end
end
