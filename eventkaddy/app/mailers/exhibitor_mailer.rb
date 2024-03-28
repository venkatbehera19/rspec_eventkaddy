# this require should really be in initializers... it's a mistunderstanding of
# how rails works that we have requires in the class files
require 'digest/sha2'
require 'nokogiri'

class ExhibitorMailer < ActionMailer::Base

	layout false
	default from: "support@eventkaddy.net"
	#default "Message-ID"=>"#{Digest::SHA2.hexdigest(Time.now.to_i.to_s)}@eventkaddy.net"

  def mail(headers = {}, &block)
    headers[:from] = "#{@event.mailer_name ? @event.mailer_name : @event.name ? @event.name : 'Support'} <support@eventkaddy.net>"
    super(headers, &block)
  end

  def set_and_email_password_bcbsa email, exhibitor, event_name
    @event = Event.find email.event_id
    @event_name = event_name
    @email = email.email
    @event_setting = EventSetting.where(event_id: @event.id).first
    # attachments.inline['banner.png'] = File.read(
    #   Rails.root.join(
    #     'public' + EventFile.find(@event_setting.portal_banner_event_file_id).path
    #   )
    # )
    @password = exhibitor.generate_and_save_simple_password
		message_id_in_header
    mail(to:@email, subject: "Your password for the #{event_name} Exhibitor Portal")
  end

  def set_and_email_password email, exhibitor
    @event = Event.find email.event_id
    @email = email.email
    template = EmailTemplate.email_password_template_for( email.event_id, "exhibitor_email_password_template" )
    password = exhibitor.generate_and_save_simple_password

    @body = template.render([exhibitor, User.where(email:exhibitor.email).first, @event, {extras: {password: password}}]) {|content|
        content.gsub(/{{event_file\((.*?)\)\.?(.*?)}}/) {|match|

          path = EventFile.find( $1 ).path
          attachments.inline["#{$1}#{File.extname path}"] = File.read( Rails.root.join( 'public' + path ))

          # we do not have a choice but to add this extension in the attachments part...
          # the url will otherwise be missing it, and then it won't work in a really confusing way.
          ActionController::Base.helpers.image_tag attachments["#{$1}#{File.extname path}"].url
        }
      }

		message_id_in_header
    mail(to:@email, subject: template.email_subject)
  end

  def message_id_in_header(sent_at = Time.now)
    headers["Message-ID"] = "#{Digest::SHA2.hexdigest(sent_at.to_i.to_s)}@eventkaddy.net"
  end

  def send_credentials_to_staff email, exhibitor_staff
    @event = Event.find email.event_id
    @email = email.email
    template = EmailTemplate.email_password_template_for( email.event_id, "exhibitor_email_password_template" )
    password = exhibitor_staff.generate_and_save_simple_password

    @body = template.render([exhibitor_staff, User.where(email:exhibitor_staff.email).first, @event, {extras: {password: password}}]) {|content|
        content.gsub(/{{event_file\((.*?)\)\.?(.*?)}}/) {|match|

          path = EventFile.find( $1 ).path
          attachments.inline["#{$1}#{File.extname path}"] = File.read( Rails.root.join( 'public' + path ))

          # we do not have a choice but to add this extension in the attachments part...
          # the url will otherwise be missing it, and then it won't work in a really confusing way.
          ActionController::Base.helpers.image_tag attachments["#{$1}#{File.extname path}"].url
        }
      }

		message_id_in_header
    mail(to:@email, subject: template.email_subject)
  end

  def send_recipt event_id, exhibitor, order = nil, email = nil
    @event     = Event.find event_id
    @exhibitor = exhibitor
    template   = EmailTemplate.email_password_template_for( event_id, "exhibitor_receipt_template" )
    settings   = Setting.return_exhibitor_registration_portal_settings(event_id)


    @is_coupon = false
    if order.nil?
      products_purchased = exhibitor.user.orders.last.order_items
    else
      products_purchased = order.order_items
      coupon_item = order.order_items.where.not(coupon_id: nil)
      if coupon_item.present?
        @is_coupon = true
      end
    end

    template.content = template.render([@exhibitor, @event]) {|content|
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
          discount_allocation = product.discount_allocations.first
          if discount_allocation
            product_table += "<td style='border: 1px solid #000;'>#{discount_allocation.complimentary_count + discount_allocation.discounted_count + discount_allocation.full_count}</td>"
            product_table += "<td style='border: 1px solid #000;'>$#{discount_allocation.amount}.00</td>"
            product_table += "</tr>"

            total_cost += discount_allocation.amount # Calculate and add the product cost to the total
          else
            product_table += "<td style='border: 1px solid #000;'>#{product.quantity}</td>"
            product_table += "<td style='border: 1px solid #000;'>$#{product.price * product.quantity}.00</td>"
            product_table += "</tr>"

            total_cost += product.price * product.quantity # Calculate and add the product cost to the total
          end
        end

        product_table += "</tbody>"

        tax_name = "Tax"
        tax_value = 0
        if settings.transaction_tax_value.present?
          tax_name  = "#{settings.transaction_tax_name} - #{settings.transaction_tax_value} %"
          tax_value = (total_cost * settings.transaction_tax_value.to_i) / 100
        end

        # Add a row for the total
        product_table += "<tfoot>"

        product_table += "<tr>"
        product_table += "<td colspan='2' style='border: 1px solid #000; text-align: right;'>#{tax_name}:</td>"
        product_table += "<td style='border: 1px solid #000;'>$#{tax_value}.00</td>"
        product_table += "</tr>"

        product_table += "<tr>"
        product_table += "<td colspan='2' style='border: 1px solid #000; text-align: right;'>Total:</td>"
        product_table += "<td style='border: 1px solid #000;'>$#{tax_value > 0 ? tax_value + total_cost : total_cost}.00</td>"
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
    if settings.receipt_attachment.present?
      transaction = Transaction.find order.transaction_id
      pdf_path = generate_pdf transaction, order, @event, settings
      attachments[pdf_path.split("/").last] = File.read(pdf_path)
    end
    sending_email = email.present? ? email : @exhibitor.email
    mail(to: sending_email, subject: template.email_subject )
    if settings.receipt_attachment.present?
      File.delete(pdf_path) if File.exist?(pdf_path)
    end
  end

  def ensure_directory_exists(dirname)
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
  end

  def generate_pdf(transaction, order, event, settings)
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
    credits_array = []
    credits_array << ["Description","Qty","Unit Price","Amount"]
    order.order_items.each do |order_item|
      if order_item.item_type == 'LocationMapping'
        product_name = order_item.item.name
      elsif order_item.item_type == 'SponsorLevelType'
        product_name = order_item.item.sponsor_type
      elsif order_item.item_type == 'Product'
        product_name = order_item.item.name
      end
      credits_array << [product_name, order_item.quantity, "$" + order_item.price.to_s, "$" + (order_item.price * order_item.quantity).to_s]

    end
    paid_at_line = "<b>$#{transaction.amount.to_s} paid on #{date_of_payment}</b>"

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

    # image_id = event.logo_event_file_id
    # event_file = EventFile.find_by(id: image_id) rescue nil
    # if event_file
    #   image = event_file.return_authenticated_url['url']
    #   pdf.image     open(image), position: :right, width:100, vposition: 0
    # end

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

    pdf.table([['SubTotal', "$" + transaction.amount.to_s ]], position: :right, column_widths:{0 => 180, 1 => 107}, cell_style: {size: 10, :inline_format => true }) do
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


    ensure_directory_exists File.dirname(Rails.root.join('public','event_data',event.id.to_s,'generated_pdfs',filename))
    pdf.render_file "./public/event_data/#{event.id}/generated_pdfs/#{filename}"
    "./public/event_data/#{event.id}/generated_pdfs/#{filename}"

  end

  def magical_link(email, event, user)
    @email = email
    @event = event
    @id = user.id

    # generating the unique token
    token = SecureRandom.hex(20)
    user.update(magic_link_token: token, magic_link_token_expires_at: Time.now + 10.day)
    @url = "#{@event.master_url}/#{@event.id}/exhibitor_registrations/confirm/user/#{token}"
    message_id_in_header
    mail(to:@email, subject: @event.name + " Magic Link for Exhibitor Registration")
  end

end
