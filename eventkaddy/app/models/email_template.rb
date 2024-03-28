class EmailTemplate < ApplicationRecord
  include EmailTemplateMethods
  # for rendering text version of email
  # def self.remove_html_tags string
  #   string.gsub(/<.*?>/,'') # non-greedy match all between <>
  # end

  # we have a genuine problem with doing templates this way, since the erb and
  # text version of the template are different... it would be nice to make a
  # generic version, but maybe not that easy
  # actually it's really not that hard... just gsub out all the tags, replace
  # <br> with \n and you're done
  # You can even do that via the render yeild block!

  # deep symbolize keys to force symbols instead of strings as keys... may end
  # up with mixed input that would be annoying to track down bugs for
  
  # def render objects end moved to module EmailTemplateMethods


  # def render_values data
  #   (block_given? ? yield(content) : content).
  #     gsub(/{{(.*?)\.(.*?)}}/) {|match|
  #       data[ $1.to_sym ] && data[ $1.to_sym ][ $2.to_sym ] || ""
  #     }.
  #     html_safe
  # end

  # this is actually not quite ideal... it assumes only one template per type.
  def self.email_password_template_for event_id, type_name
    where(event_id: event_id).where_type_name( type_name ).first || new(
      template_type_id: TemplateType.where(name: type_name).first.id,
      content:          default_content( event_id, type_name),
      email_subject:    default_email_subject( event_id, type_name ),
      event_id:         event_id
    )
  end

  # def self.default_email_subject event_id, type_name end moved to module EmailTemplateMethods


  def self.where_type_name type_name
    template_type_id = TemplateType.where(name: type_name).first.id
    where( template_type_id: template_type_id )
  end

  # instead of this, I should actually just make Example.attendee_email_password_template etc. I guess this isn't awful though.
  # Weird that we feed event_id in though, we're not using it.
  
  # def self.default_content event_id, type_name end moved to module EmailTemplateMethods

end
