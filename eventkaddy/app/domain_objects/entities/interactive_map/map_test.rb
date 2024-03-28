require_relative './symlink'
require_relative './map'
require 'minitest/autorun'

class MagickMock
	class ImageMock; def initialize(p); @path = p; end; def filename; @path; end; end
	def self.read(path); [ImageMock.new(path)]; end
end

magick_mock = Struct.new('MagickMock') { def self.read(path); [Struct.new('ImageMock') { def filename; 'dogs.jpg'; end }.new]; end }

describe InteractiveMap::Map do

	describe 'image validation' do
		it 'adds an error when map is not png' do
			jpeg_map = InteractiveMap::Map.new image_path:'./dogs.jpg', event_id:20, magick:MagickMock
			jpeg_map.errors.length.must_equal 1
		end

		it 'adds an error when map is missing' do
			map = InteractiveMap::Map.new event_id:20, magick:MagickMock
			map.errors.length.must_equal 1
		end
	end

	describe 'event_id validation' do
		it 'adds an error for event id of letters' do
			map = InteractiveMap::Map.new image_path:'./dogs.png', event_id:'ba', magick:MagickMock
			map.errors.length.must_equal 1
		end

		it 'adds an error for missing event_id' do
			map = InteractiveMap::Map.new image_path:'./dogs.png', magick:MagickMock
			map.errors.length.must_equal 1
		end
	end

	describe 'symlink validation' do
		it 'is a warning for nonexistent default symlink' do
			map = InteractiveMap::Map.new image_path:'./dogs.png', event_id:20, magick:MagickMock
			map.errors.length.must_equal 0
		end

		it 'adds an error when given nonexistent symlink' do
			map = InteractiveMap::Map.new image_path:'./dogs.png', event_id:20, magick:MagickMock, symlink:'./some_nonexistent path'
			map.errors.length.must_equal 1
		end
	end
end
