require 'digest/sha2'
require 'nokogiri'
class AttendeeMailer < ActionMailer::Base

  layout false
	default from: "support@eventkaddy.net"
	#default "Message-ID"=>"#{Digest::SHA2.hexdigest(Time.now.to_i.to_s)}@eventkaddy.net"

  def mail(headers = {}, &block)
    headers[:from] = "#{@event.mailer_name ? @event.mailer_name : @event.name ? @event.name : 'Support'} <support@eventkaddy.net>"
    super(headers, &block)
  end

  def lead_report_unavailable email, attendee
    @email = email
    @attendee = attendee
    message_id_in_header
    mail(to:@email, subject: "Lead retrieval report is not available")
  end

  def email_password_fiserv(email, password)
    @event    = Event.where(name:'Fiserv - PGA').first
    @email    = email
    @password = password
    message_id_in_header
    mail(to:@email, subject: "Your password for #{@event.name} App")
  end

  # they have a quite detailed template, and there isn't much time, so just hard coding it
  def bcbs_set_and_email_password email, attendee
    @event = Event.find email.event_id
    @email = email.email
    @password = attendee.generate_and_save_simple_numeric_password
    @attendee = attendee
		message_id_in_header
    mail(to:@email, subject: "2019 FEP Finance and Audit Meeting Mobile App Access")
  end

  # they have a quite detailed template, and there isn't much time, so just hard coding it
  def fiserv_set_and_email_password email, attendee
    @event = Event.find email.event_id
    @email = email.email
    @password = attendee.generate_and_save_simple_numeric_password
    @attendee = attendee
		message_id_in_header
    mail(to:@email, subject: "2019 FEP National Conference Mobile App Access")
  end

  def set_and_email_password email, attendee
    @event = Event.find email.event_id
    @email = email.email
    template = EmailTemplate.email_password_template_for( email.event_id, "attendee_email_password_template" )
    @password = attendee.generate_and_save_simple_numeric_password # we don't actually use this var anymore... we just call attendee.password in template.render
    if @event.send_qr_code.present?
      attendee_qr_path = attendee.qr_image_full_path
      if attendee_qr_path.present?
        attendee_qr_path = attendee_qr_path.to_s
        attachments.inline["qr_image.png"] = File.read( attendee_qr_path )
      end
    end

    @body = template.render([attendee, @event]) {|content|
        content.gsub(/{{event_file\((.*?)\)\.?(.*?)}}/) {|match|

          path = EventFile.find( $1 ).path
          attachments.inline["#{$1}#{File.extname path}"] = File.read( Rails.root.join( 'public' + path ))

          # we do not have a choice but to add this extension in the attachments part...
          # the url will otherwise be missing it, and then it won't work in a really confusing way.
          ActionController::Base.helpers.image_tag attachments["#{$1}#{File.extname path}"].url
        }
      }

		message_id_in_header
    mail(to:@email, subject: template.email_subject )
  end

  def registration_attendee_email_password(event_id, attendee, params={})
    @event = Event.find event_id
    @attendee = attendee
    template = EmailTemplate.email_password_template_for(event_id, 'registration_attendee_email_password_template' )

    if params[:user].present?
      password = params[:user][:password]
    else
      password = 'xyz1234'
    end
    template.content = template.render([@attendee, @event, {extras: {password: password}}]){|content|
      content
      .gsub(/{{event_file\((.*?)\)\.?(.*?)}}/) {|match|
        path = EventFile.find( $1 ).path
        attachments.inline["#{$1}#{File.extname path}"] = File.read( Rails.root.join( 'public' + path ))
        ActionController::Base.helpers.image_tag attachments["#{$1}#{File.extname path}"].url
      }
    }
    doc = Nokogiri::HTML(template.content)
    doc.xpath("//img").each do |img|
      path = EventFile.find(img['id']).path
      attachments.inline["#{img['id']}#{File.extname path}"] = File.read( Rails.root.join( 'public' + path ))
      image_tag = ActionController::Base.helpers.image_tag(attachments["#{img['id']}#{File.extname path}"].url, style:img['style'])
      img.replace(doc.create_text_node(image_tag))
    end
    parsed_template = doc.to_s.gsub(/(&lt;|&gt;)/) {|x| x=='&lt;' ? '<' : '>'}
    @body = parsed_template.html_safe
    message_id_in_header
    mail(to:@attendee.email, subject: template.email_subject )
  end

  def magical_link(email, event, user)
    @email = email
    @event = event
    @id = user.id
    # generating the unique token
    token = SecureRandom.hex(20)
    user.update(magic_link_token: token, magic_link_token_expires_at: Time.now + 10.day)
    @url = "#{@event.master_url}/#{@event.id}/registrations/confirm/user/#{token}"

    message_id_in_header
    mail(to:@email, subject: @event.name + " Magic Link for Attendee Registration")
  end

  def email_password(email, password)
		@email    = email
		@password = password
		message_id_in_header
		mail(to:@email, subject: "Successfully reset password.")
  end

  def email_password_reset_confirmation(email, username, token, event)
		@email    = email
		@username = username
		@token    = token
		@event    = event
		message_id_in_header
    mail(to:@email, subject: @event.name + " Password Reset Confirmation")
  end

  def email_notes(email, event, notes)
    @email = email
    @event = event
    puts "notes length: #{notes.length}"
    @session_notes = notes.where("attendee_text_uploads.session_id <> '0' OR attendee_text_uploads.session_id <> 'NULL'").order('title')
    @exhibitor_notes = notes.where("attendee_text_uploads.exhibitor_id <> '0' OR attendee_text_uploads.exhibitor_id <> 'NULL'").order('title')
    @attendee_notes = notes.where("attendee_text_uploads.target_attendee_id <> '0' OR attendee_text_uploads.target_attendee_id <> 'NULL'").order('title')
    @general_notes = notes.where(
      "IFNULL(attendee_text_uploads.session_id, 0) = 0 AND
       IFNULL(attendee_text_uploads.exhibitor_id, 0) = 0 AND
       IFNULL(attendee_text_uploads.target_attendee_id, 0) = 0").order('title')
    message_id_in_header
    mail(to:@email, subject: "Your " + @event.name + " Notes")
  end

  def email_new_message_notification(event_id, recipient, sender, title, content)
    @event                = Event.find event_id
    @recipient_name       = recipient.first_name || "there"
    @sender_name          = "#{sender.first_name} #{sender.last_name}"
    @title                = title
    @content              = content
    mail(to:recipient.email, subject: "Your received a new message")
  end

  def email_ce_certificate(email, event, filename, subject_text, content, options={})
    @email                = email
    @event                = event
    @content              = content
    filepath              = options.fetch(:path, "./public/event_data/#{@event.id}/generated_pdfs/#{filename}")
    attachments[filename] = File.read(filepath)
		message_id_in_header #this doesn't seem to consistently work.
		mail(to:@email, subject: subject_text)
  end

  def email_lead_survey_report(email, event, filename, subject_text, content, options={})
    @email                = email
    @event                = event
    @content              = content
    filepath              = options.fetch(:path, "./public/event_data/#{@event.id}/generated_lead_surveys/#{filename}")
    # must specify binary encoding for xlsx file. It would probably make more sense for this method to be fed the file
    # than for it to have any business looking it up
    attachments[filename] =  File.read(filepath, :encoding => 'BINARY')
		message_id_in_header #this doesn't seem to consistently work.
		mail(to:@email, subject: subject_text)
  end

  def registration_confirmation(event_id, attendee)
    @event     = Event.find event_id
    @attendee  = attendee
    template   = EmailTemplate.email_password_template_for( event_id, "attendee_email_confirmation_template" )
    # template.content = template.render_values({ attendee: @attendee, event: @event})

    template.content = template.render([@attendee, @event]) {|content|
      content
      .gsub(/{{event_file\((.*?)\)\.?(.*?)}}/) {|match|
        path = EventFile.find( $1 ).path
        attachments.inline["#{$1}#{File.extname path}"] = File.read( Rails.root.join( 'public' + path ))
        ActionController::Base.helpers.image_tag attachments["#{$1}#{File.extname path}"].url
      }
    }

    doc = Nokogiri::HTML(template.content)
    doc.xpath("//img").each do |img|
      path = EventFile.find(img['id']).path
      attachments.inline["#{img['id']}#{File.extname path}"] = File.read( Rails.root.join( 'public' + path ))
      image_tag = ActionController::Base.helpers.image_tag(attachments["#{img['id']}#{File.extname path}"].url, style:img['style'])
      img.replace(doc.create_text_node(image_tag))
    end
    parsed_template = doc.to_s.gsub(/(&lt;|&gt;)/) {|x| x=='&lt;' ? '<' : '>'}
    @body = parsed_template.html_safe

    message_id_in_header
    mail(to:@attendee.email, subject: template.email_subject )
  end

  def registration_attendee_receipt event_id, attendee, order = nil
    @event     = Event.find event_id
    @attendee  = attendee
    template   = EmailTemplate.email_password_template_for( event_id, "registration_attendee_receipt_template" )
    @is_coupon = false
    if order.nil?
      products_purchased = attendee.user.orders.last.order_items
    else
      products_purchased = order.order_items
      coupon_item = order.order_items.where.not(coupon_id: nil)
      if coupon_item.present?
        @is_coupon = true
      end
    end
    template.content = template.render([@attendee, @event]) {|content|
      content
      .gsub(/{{event_file\((.*?)\)\.?(.*?)}}/) {|match|
        path = EventFile.find( $1 ).path
        attachments.inline["#{$1}#{File.extname path}"] = File.read( Rails.root.join( 'public' + path ))
        ActionController::Base.helpers.image_tag attachments["#{$1}#{File.extname path}"].url
      }

      content.gsub!(/{{products_purchased}}/) do
        product_table = "<table style='border-collapse: collapse; border: 1px solid #000; width: 80%; margin: 0 auto;'>"
        product_table += "<thead>"
        product_table += "<tr>"
        product_table += "<th style='border: 1px solid #000;'>Items</th>"
        product_table += "<th style='border: 1px solid #000;'>coupon details</th>" if @is_coupon
        product_table += "<th style='border: 1px solid #000;'>Quantity</th>"
        product_table += "<th style='border: 1px solid #000;'>Cost</th>"
        product_table += "</tr>"
        product_table += "</thead>"
        product_table += "<tbody>"

        total_cost = 0 # Initialize the total cost variable

        products_purchased.each do |product|
          product_table += "<tr>"
          if product.size?
            product_table += "<td style='border: 1px solid #000;'>#{product.item.name}/size(#{product.size})</td>"
          else
            product_table += "<td style='border: 1px solid #000;'>#{product.item.name}</td>"
          end
          if @is_coupon
            if product.coupon_id?
              product_table += "<td style='border: 1px solid #000;'> #{product.coupon.coupon_code} code with $#{product.coupon_amount}.00 </td>"
            else
              product_table += "<td style='border: 1px solid #000;'> N/A </td>"
            end
          end
          product_table += "<td style='border: 1px solid #000;'>#{product.quantity}</td>"
          product_table += "<td style='border: 1px solid #000;'>$#{product.price * product.quantity}.00</td>"
          product_table += "</tr>"

          total_cost += product.price * product.quantity # Calculate and add the product cost to the total
        end

        # Add a row for the processing fee
        processing_fee_percentage = 3
        processing_fee = (total_cost * processing_fee_percentage / 100.0).round()
        product_table += "<tr>"
        product_table += "<td colspan='2' style='border: 1px solid #000;'>Processing Fee</td>"
        product_table += "<td style='border: 1px solid #000;'>$#{processing_fee}</td>"
        product_table += "</tr>"

        product_table += "</tbody>"

        # Add a row for the total
        product_table += "<tfoot>"
        product_table += "<tr>"
        product_table += "<td colspan='2' style='border: 1px solid #000; text-align: right;'>Total:</td>"
        total_with_processing_fee = total_cost + processing_fee
        product_table += "<td style='border: 1px solid #000;'>$#{total_with_processing_fee}.00</td>"
        product_table += "</tr>"
        product_table += "</tfoot>"

        product_table += "</table>"
        product_table
      end

    }

    doc = Nokogiri::HTML(template.content)
    doc.xpath("//img").each do |img|
      path = EventFile.find(img['id']).path
      attachments.inline["#{img['id']}#{File.extname path}"] = File.read( Rails.root.join( 'public' + path ))
      image_tag = ActionController::Base.helpers.image_tag(attachments["#{img['id']}#{File.extname path}"].url, style:img['style'])
      img.replace(doc.create_text_node(image_tag))
    end
    parsed_template = doc.to_s.gsub(/(&lt;|&gt;)/) {|x| x=='&lt;' ? '<' : '>'}
    @body = parsed_template.html_safe

    message_id_in_header
    settings          = Setting.return_registration_portal_settings(event_id)
    if settings.receipt_attachment.present?
      transaction = Transaction.find order.transaction_id
      pdf_path = generate_pdf transaction, order, @event
      attachments[pdf_path.split("/").last] = File.read(pdf_path)
    end
    mail(to:@attendee.email, subject: template.email_subject )
    if settings.receipt_attachment.present?
      File.delete(pdf_path) if File.exist?(pdf_path)
    end
  end

  def refund event_id, attendee, transaction
    @event       = Event.find event_id
    @attendee    = attendee
    @transaction = transaction
    template   = EmailTemplate.email_password_template_for( event_id, "attendee_refund_template" )

    template.content = template.render([@attendee, @transaction]) {|content|
      content
      .gsub(/{{event_file\((.*?)\)\.?(.*?)}}/) {|match|
        path = EventFile.find( $1 ).path
        attachments.inline["#{$1}#{File.extname path}"] = File.read( Rails.root.join( 'public' + path ))
        ActionController::Base.helpers.image_tag attachments["#{$1}#{File.extname path}"].url
      }
    }

    doc = Nokogiri::HTML(template.content)
    doc.xpath("//img").each do |img|
      path = EventFile.find(img['id']).path
      attachments.inline["#{img['id']}#{File.extname path}"] = File.read( Rails.root.join( 'public' + path ))
      image_tag = ActionController::Base.helpers.image_tag(attachments["#{img['id']}#{File.extname path}"].url, style:img['style'])
      img.replace(doc.create_text_node(image_tag))
    end
    parsed_template = doc.to_s.gsub(/(&lt;|&gt;)/) {|x| x=='&lt;' ? '<' : '>'}
    @body = parsed_template.html_safe

    message_id_in_header
    mail(to:@attendee.email, subject: template.email_subject )
  end

  def refund_complete event_id, attendee, transaction
    @event       = Event.find event_id
    @attendee    = attendee
    @transaction = transaction
    template   = EmailTemplate.email_password_template_for( event_id, "attendee_refund_complete_template" )

    template.content = template.render([@attendee, @transaction]) {|content|
      content
      .gsub(/{{event_file\((.*?)\)\.?(.*?)}}/) {|match|
        path = EventFile.find( $1 ).path
        attachments.inline["#{$1}#{File.extname path}"] = File.read( Rails.root.join( 'public' + path ))
        ActionController::Base.helpers.image_tag attachments["#{$1}#{File.extname path}"].url
      }
    }

    doc = Nokogiri::HTML(template.content)
    doc.xpath("//img").each do |img|
      path = EventFile.find(img['id']).path
      attachments.inline["#{img['id']}#{File.extname path}"] = File.read( Rails.root.join( 'public' + path ))
      image_tag = ActionController::Base.helpers.image_tag(attachments["#{img['id']}#{File.extname path}"].url, style:img['style'])
      img.replace(doc.create_text_node(image_tag))
    end
    parsed_template = doc.to_s.gsub(/(&lt;|&gt;)/) {|x| x=='&lt;' ? '<' : '>'}
    @body = parsed_template.html_safe

    message_id_in_header
    mail(to:@attendee.email, subject: template.email_subject )
  end

  def message_id_in_header(sent_at = Time.now)
    headers["Message-ID"] = "#{Digest::SHA2.hexdigest(sent_at.to_i.to_s)}@eventkaddy.net"
  end

  def ensure_directory_exists(dirname)
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
  end

  def generate_pdf(transaction, order, event)
    order       = order
    user        = order.user
    event       = event

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

    #eager loading the order_items
    order = Order.includes(:order_items).find(order.id)
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
    ensure_directory_exists File.dirname(Rails.root.join('public','event_data',event.id.to_s,'generated_pdfs',filename))
    pdf.render_file "./public/event_data/#{event.id}/generated_pdfs/#{filename}"
    "./public/event_data/#{event.id}/generated_pdfs/#{filename}"

  end

end
