class AppSubmissionForm < ApplicationRecord
  belongs_to :event
  belongs_to :app_form_type
  

  APP_SUBMISSION_FORM_UPLOAD_DIMENSIONS = {
    "android"=>{
      "android_app_icon" => "1024x1024",
      "android_landscape_splash_screen" => "1920x1080",
      "android_portrait_splash_screen" => "1080x1920",
      "android_feature_graphic" => "1024x500"
    },
    "ios"=> {
      "ios_app_icon" => "1024x1024",
      "ios_splash_screen" => "2732x2732"
    }
  }

  before_validation(:on => :create) do
    self.description = description.gsub("\r\n","\n") if self.description
  end

  validates :app_name, presence: true, length: {in: 3..30}
  validates :subtitle, presence: true, length: {in: 3..30}
  validates :description, presence: true, length: {in: 20..4000}
  validates :keywords, presence: true, length: {in: 2..100}
  validate  :check_for_form_uploads

  has_one :android_app_icon_img
  has_one :android_landscape_splash_screen_img
  has_one :android_portrait_splash_screen_img
  has_one :android_feature_graphic_img
  has_one :ios_app_icon_img
  has_one :ios_splash_screen_img

  serialize :keywords, JSON

  def restart_job_if_new_ios_image( new_image = "ios_app_icon" )
    raise "Incorrect Form type" unless self.app_form_type.name=="ios"
    if (new_image!="ios_app_icon")
      job = BackgroundJob.find_by(entity_id: self.id,entity_type: "AppSubmissionForm")
      job.delete
      background_job = BackgroundJob.create(purpose: "create_zip_file_for_app_images",status: "started",entity_id: self.id, entity_type: "AppSubmissionForm")
      CreateZipFileForAppImagesWorker.perform_async(self.event.id,self.id)
    end
  end

  def restart_job_if_new_android_image(android_app_icon="android_app_icon",android_portrait_splash_screen="android_portrait_splash_screen",android_landscape_splash_screen="android_landscape_splash_screen")

    raise "Incorrect Form type" unless self.app_form_type.name=="android"

    if (android_app_icon!="android_app_icon" ||android_portrait_splash_screen!="android_portrait_splash_screen" || android_landscape_splash_screen!="android_landscape_splash_screen")

      job = BackgroundJob.find_by(entity_id: self.id,entity_type: "AppSubmissionForm")
      job.delete
      background_job = BackgroundJob.create(purpose: "create_zip_file_for_app_images",status: "started",entity_id: self.id, entity_type: "AppSubmissionForm")
      CreateZipFileForAppImagesWorker.perform_async(self.event.id,self.id)
    end
  end

  def check_for_form_uploads
    form_type    = AppFormType.find_by!(id: self.app_form_type_id).name
    self.class::APP_SUBMISSION_FORM_UPLOAD_DIMENSIONS[form_type].keys.each do |form_type|
      type       = EventFileType.find_by(name: "#{form_type}_img")
      event_file = EventFile.where(event_id: self.event_id, event_file_type_id: type.id).first
      errors.add(:base,"#{form_type} cannot be blank.") if event_file.blank?
    end
  end

  def android_app_icon_img
    unless self.app_form_type_id == ANDROID_ID
      raise "NoMethodError: undefined method '#{__callee__}' for #{self}"
    end
    get_image_from_event_file(__callee__.to_s)
  end

  def ios_app_icon_img
    unless self.app_form_type_id == IOS_ID
      raise "NoMethodError: undefined method '#{__callee__}' for #{self}"
    end
    get_image_from_event_file(__callee__.to_s)
  end
  
  def ios_splash_screen_img
    unless self.app_form_type_id == IOS_ID
      raise "NoMethodError: undefined method '#{__callee__}' for #{self}"
    end
    get_image_from_event_file(__callee__.to_s)
  end

  def android_landscape_splash_screen_img
    unless self.app_form_type_id == ANDROID_ID
      raise "NoMethodError: undefined method '#{__callee__}' for #{self}"
    end
    get_image_from_event_file(__callee__.to_s)
  end

  def android_portrait_splash_screen_img
    unless self.app_form_type_id == ANDROID_ID
      raise "NoMethodError: undefined method '#{__callee__}' for #{self}"
    end
    get_image_from_event_file(__callee__.to_s)
  end

  def android_feature_graphic_img
    unless self.app_form_type_id == ANDROID_ID
      raise "NoMethodError: undefined method '#{__callee__}'e for #{self}"
    end
    get_image_from_event_file(__callee__.to_s)
  end

  private

  def get_image_from_event_file image_type
    event_file_type_id = EventFileType.find_by(name: image_type).id
    EventFile.find_by(event_id: self.event_id, event_file_type_id: event_file_type_id)
  end

end
