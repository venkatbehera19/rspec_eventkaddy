class Styles

  class Style
    attr_reader :selector, :property, :value, :label, :dictionary

    def initialize(args)
      @selector   = args[:selector]
      @property   = args[:property]
      @value      = args[:value]
      @label      = args[:dictionary]["#{@selector}_#{@property}"]
    end
  end

  attr_reader :file_paths, :parser, :styles_by_category, :style, :category_dictionary, :style_dictionary, :overwritten

  def initialize(args)
    @parser              = CssParser::Parser.new ## Dependency
    @style               = Style ## Dependency
    @file_paths          = args[:file_paths]
    @style_dictionary    = args.fetch(:style_dictionary, {})
    @category_dictionary = args.fetch(:category_dictionary, {})
    @styles_by_category  = {}
    @overwritten         = []
    ensure_paths(file_paths)
    load_css_files
    populate_styles
  end

  def as_css
    parser.to_s
  end

  private

  def ensure_paths(paths)
    paths.each {|p|
      FileUtils.mkdir_p(File.dirname(p)) unless File.directory?(File.dirname(p))}
  end

  def load_css_files
    file_paths.each {|path|
      parser.load_uri! path if File.exist?(path)}
  end

  def parse_property(d)
    d.split(':')[0]
  end

  def parse_value(d)
    d.split(':',2)[1].strip
  end

  def return_category(selector, property)
    category_dictionary["#{selector}_#{property}"] || 'Miscellaneous'
  end

  def append_style(selector, property, value)
    category = return_category(selector, property)
    styles_by_category[category] ||= []
    styles_by_category[category] << style.new(selector:selector, property:property, value:value, dictionary:style_dictionary)
  end

  def iterate_declarations(selector, declarations)
    declarations[0...-1].split('; ').each {|declaration|
      property = parse_property(declaration)
      next if overwritten.include? "#{selector}_#{property}"; overwritten << "#{selector}_#{property}";
      append_style(selector, property, parse_value(declaration))}
  end

  def populate_styles
    parser.each_selector(:all) {|selector, declarations|
      iterate_declarations(selector, declarations)}
  end

end
