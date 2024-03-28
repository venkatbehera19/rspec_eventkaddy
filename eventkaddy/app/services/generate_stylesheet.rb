class GenerateStylesheet

  def initialize(args)
    @styles         = args[:styles] ## EX: {".lvnavbar_color"=>"#000", ".lvnavbar_background-color"=>"#FFF"}
    @path_to_save   = args[:path_to_save]
    @styles_refined = {}
    @output_string  = ''
  end

  def call
    generate
  end

  private

  attr_reader :styles, :styles_refined, :output_string, :path_to_save

  def concat_selector(selector, declarations)
    output_string.concat "#{selector}{"
    declarations.each {|declaration|
      output_string.concat "#{declaration[:property]}:#{declaration[:value]};"}
    output_string.concat "}"
  end

  def create_styles_string
    styles_refined.each {|selector, declaration|
      concat_selector(selector, declaration)}
  end

  def refine_style(input_name, input_value)
    selector = input_name.split('_')[0]
    property = input_name.split('_')[1]
    styles_refined[selector] ||= []
    styles_refined[selector] << {property:property, value:input_value}
  end

  def refine_styles
    styles.each {|input_name, input_value|
      refine_style(input_name, input_value)}
  end

  def generate
    refine_styles
    create_styles_string
    File.open(path_to_save, 'wb', 0777) { |f| f.write(output_string) }
  end

end