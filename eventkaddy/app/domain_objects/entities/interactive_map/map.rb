module InteractiveMap

  class Map

    MINIMAP_SIZE = 200

    attr_reader :event_id, :symlink

    def initialize(args)
      @image_path = args[:image_path]
      @event_id = args[:event_id].to_s
      @magick = args[:magick] || Magick::Image
      @symlink = args[:symlink] || InteractiveMap::Symlink
      map_image && png?; event_id?; symlink?
    end

    def write_images
      map_image.write "#{symlink}/images/#{event_id}.#{extension}"
      minimap_image.write "#{symlink}/images/#{event_id}_small.#{extension}"
    end

    # Don't need this for now, but if we do, removal of an interactive map projects images will need to be in a place
    # that does not mandate an image path in its initialization.
    # def remove_images
    #   File.delete "#{symlink}/images/#{event_id}.#{extension}", "#{symlink}/images/#{event_id}_small.#{extension}"
    # end

    def extension
      map_image.format.downcase
    end

    def map_image ## rename full image?
      @map_image ||= @magick::read(@image_path).first
    rescue
      magick_error
    end

    def minimap_image
      @minimap_image ||= generate_minimap
    end

    def height
      map_image.rows
    end

    def width
      map_image.columns
    end

    def generate_minimap
      map_image.change_geometry("#{MINIMAP_SIZE}x#{MINIMAP_SIZE}") { |cols, rows, image|	image.resize(cols, rows) }
    end

    def errors
      @errors ||= []
    end

    def png?
      map_image.filename && map_image.filename[-4..-1].downcase == '.png' ? true : png_error
    end

    def event_id?
      # is a whole positive number?
      /\A\d+\z/ === event_id ? true : event_id_error
    end

    def symlink?
      File.exists?(@symlink) ? true : symlink_error
    end

    private

    def png_error
      errors << 'WARNING: Interactive map must be a PNG. Please reupload the image file or the interactive map will not function.'
      false
    end

    def event_id_error
      errors << "WARNING: Event ID was not provided or was not valid. Received: #{event_id}"
      false
    end

    def symlink_error
      errors << "WARNING: Symlink for Interactive Map does not exist."
      false
    end

    def magick_error
      errors << "WARNING: An error occured while trying to process your image."
      false
    end
  end
end
