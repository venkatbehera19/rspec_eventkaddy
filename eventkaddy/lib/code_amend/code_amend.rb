module CodeAmend

  class Line

    attr_accessor :indentation_string, :string, :indentation_level

    def initialize string, indentation_level = 0
      @string             = string
      @indentation_level  = indentation_level
      @indentation_string = "\s\s"
    end

    def to_s
      indentation_string * indentation_level + string
    end
  end

  class Lines

    attr_reader :array

    def initialize array
      @array = array
    end

    def to_s
      array.map {|l| l.to_s }.join "\n" 
    end

    # named at_index instead of [] to avoid confusion that instances of this class are an array
    def at_index(key)
      array[key]
    end
  end

  class Code

    attr_reader :path, :code

    def initialize path 
      @path = path
      @code = File.readlines path 
    end

    def line_exists? line
      code.select {|l| l == line.to_s + "\n" }.length > 0
    end

    def line_matches line, string
      line =~ /#{Regexp.quote(string)}/
    end

    def replace_first_from_bottom search_term, replacement
      found = false
      code.reverse!
      code.map! {|l| break if found; line_matches(l, search_term) ? (found = true; l = replacement ) : l }
      code.reverse!
    end

    # TODO: there is a flaw with these two methods; if the search term
    # is only partial, the rest of the line will be deleted
    def append_after search_term, lines 
      replace_first_from_bottom search_term, "#{search_term}\n\n#{lines.to_s}\n"
    end

    def append_before search_term, lines
      replace_first_from_bottom search_term, "#{lines.to_s}\n\n#{search_term}\n"
    end

    def add_block_to_class lines
      append_after "  ## Auto Generated Methods Start ## Do Not Delete This Comment", lines
    end

    def append_to_last_block lines 
      append_before "end", lines 
    end

    def remove lines
      line = lines.to_s + "\n"
      idx = code.find_index(line)
      code.delete_at(idx)
      # second delete is deletion of \n
      code.delete_at(idx)
    end

    def remove_block lines
      block_size  = lines.array.length() - 1
      start_index = code.find_index(lines.at_index(0).to_s + "\n")
      return if start_index.blank?
      end_index   = start_index + block_size.to_i
      code.slice!(start_index..end_index)
    end

    def write args = {} 
      save_path = args[:new_path] || path
      File.open(save_path, 'w') { |f| f.puts code.join }
    end
  end

end

