# This class helps you setup forms that are dependent on the settings table.
# The most generic method is if_setting, which takes a block and executes and 
# returns the result of the block if the setting is set to show.
#
# More helpful shortcuts could be created for sepcific form types, or they can
# be made as per-form lambdas as was the pattern before this.

class FormWithSettings

  attr_accessor :settings

  def initialize type, event_id
    @settings = Setting.send( "return_#{type}", event_id)
  end

  def if_setting setting
    yield if settings.method( setting ).call
  end

  def unless_setting setting
      yield unless settings.method( setting ).call
  end

  def visible? setting
    if Setting.method_defined? "hide_#{ setting.to_s }"
      !settings.method( "hide_#{ setting.to_s }" ).call
    elsif Setting.method_defined? "show_#{ setting.to_s }"
      settings.method( "show_#{ setting.to_s }" ).call
    elsif setting == "contact_name"
      !settings.contact_name
    elsif setting == "contact_title"
      !settings.contact_title
    end
  end

  def locked? setting
    settings.method( "locked_#{ setting.to_s }" ).call
  end

  def text_area form, column, label=nil, options={}

    # <%= f.text_area :biography, style:"min-width:350px;", readonly: true %>
    form_method :text_area, form, column, label, options
  end

  # Is this safe? we're calling html_safe on text that contains user text.
  # looks like it is fine. Maybe rails does something. Script tags activate
  def text_field form, column, label=nil, options={}
    form_method :text_field, form, column, label, options
    # if visible?(column)
    #   "<div class='field'>
    #       #{ form.label column.to_sym, label }
    #       #{ form.text_field column.to_sym, disabled: locked?(column) }
    #       <br><br>
    #   </div>".html_safe
    # else
    #   ""
    # end
  end

  def form_method method, form, column, label=nil, options={}
    if visible?(column)
      "<div class='form-group'>
          #{ form.label column.to_sym, label }
          #{ form.send method, column.to_sym, { disabled: locked?(column) }.merge(options) }
      </div>".html_safe
    else
      ""
    end
  end

end

