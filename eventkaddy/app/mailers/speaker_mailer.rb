# this require should really be in initializers... it's a mistunderstanding of
# how rails works that we have requires in the class files
require 'digest/sha2'

class SpeakerMailer < ActionMailer::Base

	default from: "support@eventkaddy.net"

  def mail(headers = {}, &block)
    headers[:from] = "#{@event.mailer_name ? @event.mailer_name : @event.name ? @event.name : 'Support'} <support@eventkaddy.net>"
    super(headers, &block)
  end

  def set_and_email_password_bcbsa email, speaker, event_name
    @event = Event.find email.event_id
    @event_name = event_name
    @email = email.email
    @event_setting = EventSetting.where(event_id: @event.id).first
    attachments.inline['banner.png'] = File.read(
      Rails.root.join(
        'public' + EventFile.find(@event_setting.portal_banner_event_file_id).path
      )
    )
    @password = speaker.generate_and_save_simple_password
		message_id_in_header
    mail(to:@email, subject: "Your password for the #{event_name}")
  end

  def set_and_email_password email, speaker
    @speaker = speaker
    @speaker.email = email.email
    @event = Event.find email.event_id
    @email = email.email
    template = EmailTemplate.email_password_template_for( email.event_id, "speaker_email_password_template" )
    password = @speaker.generate_and_save_simple_password

    template.content = template.render([@speaker, @event, {extras: {password: password}}]){|content|
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
    mail(to:@email, subject: template.email_subject )
  end

  def message_id_in_header(sent_at = Time.now)
    headers["Message-ID"] = "#{Digest::SHA2.hexdigest(sent_at.to_i.to_s)}@eventkaddy.net"
  end

  def registration_confirmation(event_id, speaker)
    @event = Event.find event_id
    @speaker = speaker
    template = EmailTemplate.email_password_template_for(event_id, 'speaker_email_confirmation_template')
    template.content = template.render([@speaker, @event]) {|content|
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
    mail(to:@speaker.email, subject: template.email_subject )
  end

  def speaker_email_password(event_id, speaker, params={})
    @event = Event.find event_id
    @speaker = speaker
    template = EmailTemplate.email_password_template_for(event_id, 'speaker_email_password_template' )  
      
    if params[:user].present?
      password = params[:user][:password]
    else
      password = 'xyz1234'
    end
    template.content = template.render([@speaker, @event, {extras: {password: password}}]){|content|
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
    mail(to:@speaker.email, subject: template.email_subject )
  end

  def speaker_numeric_password (event_id, speaker, params={})
    @event = Event.find event_id
    @speaker = speaker
    
    template = EmailTemplate.email_password_template_for(event_id, 'speaker_numeric_password_template')
    if params[:user].present?
      password = params[:password]
    else
      password = '123098'
    end
    template.content = template.render([@speaker, @event, {extras: {password: password}}]){|content|
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
    mail(to: @speaker.email, subject: template.email_subject )
  end

end
