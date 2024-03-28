class CustomFormsController < ApplicationController

  layout 'subevent_2013'
  load_and_authorize_resource

  def index
    event        = Event.find session[:event_id]
    @custom_forms = event.custom_forms
  end

  def new 
  end

  def create
    name                = params[:name]
    custom_form_type_id = params[:customFormType]
    form_data           = params[:formData]

    custom_form_type = CustomFormType.where(id: custom_form_type_id)

    begin
      forms_data = JSON.parse(form_data)

      forms_data.each do |form_data|
        parsed_data = Nokogiri::HTML.parse(form_data["label"])
        label = parsed_data.children.text
        form_data["name"] = label.strip().split(" ").join("-")
      end

      CustomForm.create(
        name: name, 
        custom_form_type_id: custom_form_type.first.id, 
        json: forms_data, 
        event_id: session[:event_id]
      )
      # binding.pry
    rescue => exception
      is_error = true
      puts exception
    end
    if !is_error
      render json: { success: true }
    else
      render json: { success: false }
    end
  end

  def update
    custom_form_id      = params[:id]
    name                = params[:name]
    custom_form_type_id = params[:customFormType]
    form_data           = params[:formData]
    custom_form         = CustomForm.where(id: custom_form_id).first
    
    begin
      forms_data = JSON.parse(form_data)
      
      forms_data.each do |form_data|
        parsed_data = Nokogiri::HTML.parse(form_data["label"])
        label = parsed_data.children.text
        form_data["name"] = label.strip().split(" ").join("-")
      end
      updated_custom_form = custom_form.update_columns(name: name, custom_form_type_id: custom_form_type_id, json: forms_data)
      
    rescue => exception
      is_error = true
      puts exception
    end

    if !is_error && updated_custom_form
      render json: { success: true }
    else
      render json: { success: false }
    end

  end

  def show
    id = params[:id]
    @custom_form = CustomForm.where(id: id).first
  end

  def destroy
    custom_form = CustomForm.find params[:id]
    if custom_form.delete
      redirect_to custom_forms_path, :notice => "Custom Form Deleted Successfully"
    else
      redirect_to custom_forms_path, :alert => "Something went wrong!"
    end
  end

end