require_relative './styles.rb'
require 'minitest/autorun'
require 'css_parser'
require 'fileutils'

class StylesTest < Minitest::Unit::TestCase

  attr_reader :styles

  def setup
    @styles = Styles.new(file_paths:["./test_data/tailored.css", "./test_data/tailored_default.css"])
  end

  def test_styles_by_category
    assert styles.styles_by_category.kind_of?(Hash), 'Expected hash'
    assert_equal styles.styles_by_category["Miscellaneous"].first.value, '#ffffff', 'Tailored should override tailored_default'
  end

  def test_as_css
    assert styles.as_css.kind_of?(String), "Expected string"
  end
end
