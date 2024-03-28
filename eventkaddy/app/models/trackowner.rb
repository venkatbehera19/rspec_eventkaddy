class Trackowner < ApplicationRecord
  include Magick

  belongs_to :event_file_photo, :foreign_key => 'photo_event_file_id', :class_name => "EventFile", :optional => true

  has_many :sessions_trackowners
  has_many :sessions, :through => :sessions_trackowners
  has_many :session_files, :through => :sessions
  has_many :speakers, :through => :sessions
  has_many :speaker_files, :through => :speakers

  belongs_to :user, :optional => true

  before_create :generate_token


  def full_name
    return "#{self.honor_prefix} #{self.first_name} #{self.last_name} #{self.honor_suffix}"
  end

  def updatePhoto(params)

    if (params[:photo_file]!=nil) then #update/add photo

      uploaded_io = params[:photo_file]

      #upload the speaker photo
      if (uploaded_io.original_filename.match(/jpeg|jpg/i)) then
        file_ext = '.jpg'
      elsif (uploaded_io.original_filename.match(/png/i)) then
        file_ext = '.png'
      else
        return
      end

      new_filename = "#{self.first_name}_#{self.last_name}_photo_#{Time.now().strftime('%Y%m%d%H%M%S')}#{file_ext}"

      #create directory structure if necessary
      dirname = File.dirname(Rails.root.join('public','event_data', self.event_id.to_s,'trackowner_photos',new_filename))
      unless File.directory?(dirname)
        FileUtils.mkdir_p(dirname)
      end

      File.open(Rails.root.join('public','event_data', self.event_id.to_s,'trackowner_photos',new_filename), 'wb',0777)      do |file|
        file.write(uploaded_io.read)
      end

      if (self.event_file_photo==nil) then
        self.event_file_photo = EventFile.new()
      end

      @event_file_type = EventFileType.where(name:'speaker_photo').first
      self.event_file_photo.event_file_type_id=@event_file_type.id

      self.event_file_photo.event_id=self.event_id
      self.event_file_photo.name=new_filename
      self.event_file_photo.path="/event_data/#{self.event_id.to_s}/trackowner_photos/#{new_filename}"
      self.event_file_photo.save()

      #resize image
      img = Image.read(Rails.root.join('public').to_s + self.event_file_photo.path).first
          img.change_geometry('150x150') { |cols, rows, img|
            img.resize!(cols,rows)
          }
          img.write(Rails.root.join('public').to_s + self.event_file_photo.path)


    end

  end

  def createPhotoPlaceholder()

    if (self.event_file_photo==nil) then
      self.event_file_photo = EventFile.new()
    end

    @event_file_type = EventFileType.where(name:'speaker_photo').first
    self.event_file_photo.event_file_type_id=@event_file_type.id

    self.event_file_photo.event_id=self.event_id
    self.event_file_photo.name=self.photo_filename
    self.event_file_photo.path="/event_data/#{self.event_id.to_s}/trackowner_photos/#{new_filename}"
    self.event_file_photo.save()

  end

  def bundleSpeakerFiles
    photosfolder          = Rails.root.join('public','event_data', self.event_id.to_s,'speaker_photos')
    filesfolder           = Rails.root.join('download','event_data', self.event_id.to_s,'speaker_files')

    #create directory structure if necessary
    unless File.directory?(photosfolder)
      FileUtils.mkdir_p(photosfolder)
    end
    unless File.directory?(filesfolder)
      FileUtils.mkdir_p(filesfolder)
    end

    #create directory structure if necessary
    unless File.directory?(photosfolder)
      FileUtils.mkdir_p(photosfolder)
    end
    unless File.directory?(filesfolder)
      FileUtils.mkdir_p(filesfolder)
    end

    photosinput_filenames = []
    filesinput_filenames  = []

    self.speakers.select('DISTINCT speakers.*').where("photo_event_file_id IS NOT NULL").each do |speaker|
      photosinput_filenames << speaker.event_file_photo.name
    end

    self.speakers.select('DISTINCT speakers.*').each do |speaker|
      speaker.speaker_files.each do |file|
        filesinput_filenames << file.event_file.name
      end
    end

    FileUtils.rm filesfolder + "#{self.email}_speaker_files.zip", :force => true

    zipfile_name = filesfolder + "#{self.email}_speaker_files.zip"

    Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
      photosinput_filenames.each do |filename|
        zipfile.add("speaker_photos/"+filename, photosfolder + filename)
      end

      filesinput_filenames.each do |filename|
        zipfile.add("speaker_files/"+filename, filesfolder + filename)
      end
    end
  end

  def bundleSessionFiles
    folder = Rails.root.join('public','event_data', self.event_id.to_s,'session_files')

    #create directory structure if necessary
    unless File.directory?(folder)
      FileUtils.mkdir_p(folder)
    end

    input_filenames = []

    self.sessions.select('DISTINCT sessions.*').each do |session|
      session.session_files.each do |session_file|
        if session_file.session_file_versions.length > 0
          input_filenames << session_file.session_file_versions.last.event_file.name
        end
      end
    end

    FileUtils.rm folder + "#{self.email}_session_files.zip", :force => true

    zipfile_name = folder + "#{self.email}_session_files.zip"

    Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
      input_filenames.each do |filename|
        zipfile.add("session_files/"+filename, folder + filename)
      end
    end
  end

  def generate_token
    self.token = loop do
      random_token = SecureRandom.urlsafe_base64(nil, false)
      break random_token unless Trackowner.exists?(token: random_token)
    end
  end

end
