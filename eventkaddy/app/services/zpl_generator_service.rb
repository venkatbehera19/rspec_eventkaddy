class ZplGeneratorService
  def initialize(font_type, orientation, size, text, x, y, badge_width = 400)
    @font_type   = font_type
    @orientation = orientation
    @size        = validate_size(size)
    @text        = text
    @x           = x
    @y           = y
    @badge_width = badge_width * 2
  end

  def call
    # Font type mapping
    font_types = {
      'default'     => 'A', #default font
      'bold'        => 'B', #bold font
      'medium'      => 'C', #medium bold font
      'large'       => 'D', #large bold font
      'extra-large' => 'E'  #extra-large bold font
    }

    # Orientation mapping
    orientations = {
      'Normal'    => 'N',
      'Rotated'   => 'R',
      'Inverted'  => 'I',
      'Bottom-up' => 'B'
    }

    # setting up default values
    font_type_code   = font_types[@font_type]     || 'A'
    orientation_code = orientations[@orientation] || 'N'

    # handling with size
    size_result = @size * 10
    height = size_result
    width  = size_result

    # constructing zpl code
    zpl_code = "^FO#{0},#{@y}\n^A#{font_type_code}#{orientation_code},#{height},#{width}\n^FB#{@badge_width},4,30,C^FD#{@text}^FS"

    return zpl_code
  end

  private

  def validate_size(size)
    size = size.to_i
    size = [1, size, 10].sort[1]
  end

end
