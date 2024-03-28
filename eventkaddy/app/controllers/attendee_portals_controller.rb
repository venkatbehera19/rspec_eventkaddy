class AttendeePortalsController < ApplicationController
  layout :set_layout
  before_action :require_login, :get_settings, only: [:landing, :profile, :edit_profile, :my_orders]
  before_action :authenticate_user!

  include AttendeePortal

  def landing
    @attendee = Attendee.find_by_slug(params[:slug])
    @user = @attendee.user
    if params[:slug].present?
      session[:slug] = params[:slug]
    end
    @current_tab = get_current_tab("Welcome")
  end

  def profile
    @attendee = current_user.attendee
    @event    = Event.find session[:event_id]
    @current_tab = get_current_tab("Profile")
  end

  def edit_profile
    @attendee = current_user.attendee
  end

  def update_profile
    @attendee = current_user.attendee
      if @attendee.update!(attendee_params)
        redirect_to "/attendee_portals/profile", notice: 'Profile was successfully updated.'
      else
        redirect_to "attendee_portals/edit_profile", alert: @attendee.errors.full_messages.to_sentence
      end
  end

  def edit_survey
    @attendee = current_user.attendee
  end

  def update_survey
    @attendee = current_user.attendee

    fields = JSON.parse @attendee.custom_fields
    fields.each do |field|
      field["value"] = params[:user][field["name"]]

      if field['type'] == "radio-group"
        field['values'].each do |radio_field|
          if radio_field["value"] == params[:user][field["name"]]
            radio_field["selected"] = true
          else
            radio_field["selected"] = false
          end
        end
      end

      if field['type'] == "checkbox-group"
        if params[:user][field['name']]
          field['values'].each do |check_field|
            if params[:user][field['name']].include?(check_field["value"])
              check_field["selected"] = true
            else
              check_field["selected"] = false
            end
          end
        end
      end
    end

    if fields
      @attendee.update_column(:custom_fields, JSON.generate(fields))
    else
      @attendee.update_column(:custom_fields, JSON.generate([]))
    end

    redirect_to "/attendee_portals/profile", notice: 'Survey form was successfully updated.'
  end

  def logout_attendee
    signout_attendee
  end

  def my_orders
    @orders = current_user.orders.includes(:order_items, [transaction_detail: :mode_of_payment]).where(mode_of_payment: {event_id: session[:event_id]})
    @current_tab = get_current_tab("My Orders")
  end

  def download_invoice
    transaction = Transaction.find_by(id: params[:transaction_id])

    def send_pdf(pdf)
      send_data pdf.render, type: "application/pdf"
    end

    def ensure_directory_exists(dirname)
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
    end

    def generate_pdf(transaction)
      order       = Order.where(transaction_id: transaction.id).last
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
      #{event.organization.zip}"

      payee = "Bill To
      #{"#{user.first_name} #{user.last_name}".strip}
      #{user.email}
      "
      coupon_item = order.order_items.where.not(coupon_id: nil)
      credits_array = []
      if coupon_item.present?
        credits_array << ["Description","Coupon Details","Qty","Unit Price","Amount"]
      else
        credits_array << ["Description","Qty","Unit Price","Amount"]
      end
      order.order_items.each do |order_item|
        if order_item.item_type == 'LocationMapping'
          product_name = order_item.item.name
        elsif order_item.item_type == 'SponsorLevelType'
          product_name = order_item.item.sponsor_type
        elsif order_item.item_type == 'Product'
          if order_item.size?
            product_name = "#{order_item.item.name}/size(#{order_item.size})"
          else
            product_name = order_item&.item&.name
          end
        end
        product_price = sprintf "%.2f",order_item.price
        product_amount = sprintf "%.2f",(order_item.price * order_item.quantity)

        if coupon_item.present?
          coupon_details = ""
          if order_item.coupon_id?
            coupon_details = "#{order_item.coupon.coupon_code} with
             discount $ #{order_item.coupon_amount}.00"
          else
            coupon_details = "N/A"
          end
          credits_array << [product_name, coupon_details, order_item.quantity, "$ " + product_price , "$ " + product_amount ]
        else
          credits_array << [product_name, order_item.quantity, "$ " + product_price , "$ " + product_amount ]
        end

      end

      paid_at_line = "<b>$ #{sprintf "%.2f",transaction.amount} paid on #{date_of_payment}</b>"

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

      if coupon_item.present?
        pdf.table(credits_array, position: :center, column_widths:{0 => 150, 1 => 100, 2 => 90, 3 => 90, 4 => 100}, cell_style: {size: 10, :inline_format => true }) do
          cells.padding = 10
          cells.borders = []
          row(0).borders = [:bottom]
          style(row(0), font_style: :bold)
        end
      else
        pdf.table(credits_array, position: :center, column_widths:{0 => 250, 1 => 90, 2 => 90, 3 => 100}, cell_style: {size: 10, :inline_format => true }) do
          cells.padding = 10
          cells.borders = []
          row(0).borders = [:bottom]
          style(row(0), font_style: :bold)
        end
      end

      total_amount = sprintf "%.2f",order.order_items.reduce(0){|sum,item| sum+=(item.quantity*item.price)}.to_s

      pdf.table([['SubTotal', "$ " + total_amount ]], position: :right, column_widths:{0 => 180, 1 => 107}, cell_style: {size: 10, :inline_format => true }) do
        cells.padding = 10
        cells.borders = []
        cells.border_lines = [:dotted]
        row(0).borders = [:bottom, :top]
      end


      processing_fee_percentage = 3
      processing_fee = (total_amount.to_f * processing_fee_percentage / 100.0).round()
      processing_fee_amount = sprintf "%.2f", processing_fee

      pdf.table([['Processing fees', "$ " + processing_fee_amount.to_s ]], position: :right, column_widths:{0 => 180, 1 => 107}, cell_style: {size: 10, :inline_format => true }) do
        cells.padding = 10
        cells.borders = []
        cells.border_lines = [:dotted]
        row(0).borders = [:bottom, :top]
      end

      total_order_amount = sprintf "%.2f",transaction.amount

      pdf.table([['Total Paid', "$ " + total_order_amount ]], position: :right, column_widths:{0 => 180, 1 => 107}, cell_style: {size: 10, :inline_format => true }) do
        cells.padding = 10
        cells.border_lines = [:dotted]
        row(0).borders = [:bottom, :top]
      end

      filename = "Invoice Transaction Id #{transaction.id}.pdf"

      ensure_directory_exists File.dirname(Rails.root.join('public','event_data',event_id.to_s,'generated_pdfs',filename))

      pdf.render_file "./public/event_data/#{event_id}/generated_pdfs/#{filename}"
      "/event_data/#{event_id}/generated_pdfs/#{filename}"
    end

    respond_to do |format|
      if transaction
        format.html {redirect_to(generate_pdf(transaction)) }
      else
        format.html {redirect_to("/attendee_portals/my_orders")}
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
        # binding.pry
        attendee = Attendee.where( event_id: session[:event_id], user_id: @user.id ).first
        if attendee.present?
          attendee.update_column(:password, user_params[:password])
        end
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

  private

    def get_settings
      @settings = Setting.return_attendee_portal_settings({ event_id: current_user.attendee.event_id })
    end

    def set_layout
      @current_user = current_user
      if current_user.role? :attendee then
        'attendeeportal'
      else
        'subevent_2013'
      end
    end

    def get_current_tab default_name
      current_tab = Tab.tab_by_event_and_default_name session[:event_id], default_name, 'attendee_portal'
    end

    def require_login
      !user_signed_in? && (redirect_to "/#{session[:event_id]}/registrations/login_to_profile", :alert => "You need to sign in.")
    end

    def user_params
      params.require(:user).permit(:password, :password_confirmation, :current_password)
    end

    def attendee_params
      params.require(:attendee).permit(:email, :username, :first_name, :last_name, :honor_prefix, :honor_suffix, :title, :company, :biography, :business_unit, :business_phone,
       :mobile_phone, :country, :state, :city, :notes_email, :notes_email_pending, :temp_photo_filename, :photo_filename, :photo_event_file_id,
       :iattend_sessions, :assignment, :validar_url, :publish, :twitter_url, :facebook_url, :linked_in, :username, :attendee_type_id,
       :messaging_opt_out, :messaging_notifications_opt_out, :app_listing_opt_out, :game_opt_out, :first_run_toggle, :video_portal_first_run_toggle,
       :custom_filter_1, :custom_filter_2, :custom_filter_3, :pn_filters, :token, :tags_safeguard, :speaker_biography, :custom_fields_1, :survey_results,
       :travel_info, :table_assignment, :custom_fields_2, :custom_fields_3, :password)
    end
end
