class ExhibitorSticker < ApplicationRecord
  belongs_to :exhibitor
  belongs_to :event_file
  belongs_to :event

  def save_and_update_sticker(sticker_file)
    code = !exhibitor.exhibitor_code.blank? ? exhibitor.exhibitor_code : exhibitor.id

    #file name standardization
    new_filename = "#{code}_exhibitor_sticker_#{Time.now().strftime('%Y%m%d%H%M%S')}_#{sticker_file.original_filename}"
    new_filename.gsub!(/\s/,'_')
    new_filename.gsub!(/[^0-9A-Za-z.\-]/, '_')

    #save the file on server
    destination = Rails.root.join('public', 'event_data', event_id.to_s,'exhibitor_sticker', new_filename)
    dirname = destination.dirname
    FileUtils.mkdir_p dirname unless File.directory? dirname
    File.open(destination, 'wb') do |file|
      file.write sticker_file.read
    end
    
    #Update event_file data
    event_file ||= EventFile.new
    event_file_type_id = EventFileType.where(name: 'exhibitor_sticker').first_or_create.id
    event_file.event_file_type_id = event_file_type_id
    event_file.event_id = event_id
    event_file.mime_type = sticker_file.content_type
    event_file.size = sticker_file.size
    event_file.name = new_filename
    event_file.path = "/event_data/#{event_id.to_s}/exhibitor_sticker/#{new_filename}"
    event_file.save!

    #save the sticker data
    self.event_file_id = event_file.id
    save!
  end

  def self.update_positions(records)
    records.each { |record| self.update record["id"], {z_index_position: record["order"]} }
  end
end
