module CustomFormsHelper 

  def custom_form_options(type_id = nil)
    options = ''
    options << "<option value='0'>None</option>"
    custom_form_types = CustomFormType.all
    custom_form_types.each do |custom_form_type|
      options << "<option value='#{custom_form_type.id}' #{'selected' if custom_form_type.id = type_id}>#{custom_form_type.name}</option>"
    end
    options.html_safe
  end

end