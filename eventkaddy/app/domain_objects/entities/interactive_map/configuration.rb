module InteractiveMap
  class Configuration

    attr_reader :hash

    def initialize(symlink = InteractiveMap::Symlink)
    	@config_file_path = "#{symlink.to_s}/js/map_data.js"
      parse
    end

    def update(event_id, width, height)
      @hash[event_id.to_s] = {'w' => width, 'h' => height}
      write
    end

    def remove(event_id)
      @hash.delete event_id.to_s
      write
    end

    def write
      File.open(@config_file_path, 'w') {|f| f.write "var map_dimensions = #{@hash.to_json};" }
    end

    def parse
      raise symlink_error unless File.exists? @config_file_path
    	begin; @hash = JSON.parse(get_file_contents); rescue; raise read_error; end
    end

    def get_file_contents
      remove_non_json_javascript File.open(@config_file_path, "r") {|f| f.read }
    end

    def remove_non_json_javascript json
      json.split.join(' '); json.gsub!('var map_dimensions = ', ''); json.gsub!('};', '}')
    end

    def read_error
      "Config file could not be updated as it could not be parsed."
    end

    def symlink_error
      "Interactive Map path incorrectly set."
    end
  end
end
