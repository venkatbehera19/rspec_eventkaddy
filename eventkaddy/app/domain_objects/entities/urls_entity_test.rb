require_relative './urls_entity.rb'
require 'active_support/core_ext/object/blank'
require 'minitest/autorun'
require 'json'

class UrlsArrayFactory

  attr_reader :array

  def initialize(number)
    @array = []
    @number = number
    generate_array
  end

  def extensions
    %w[.doc .docx .ods .pdf .txt .rtf .ppt pptx .xls .xlsx .xlsx .mov .mp4 .mp3 .pez]
  end

  def random_string
    ('a'..'z').to_a.shuffle[0,8].join
  end

  def random_number
    (0..9).to_a.shuffle[0,5].join
  end

  def generate_array
    ext = extensions.sample
    @number.times {|n|
      array << {'sf_id' => random_number, 'title' => "#{random_string} #{random_string}", 'url' => "/#{random_string}/#{random_string}#{ext}",'type' => ext}
    }
  end

end

describe UrlsEntity do

	before do
		@array = UrlsArrayFactory.new(1).array
		@json  = @array.to_json
	end

	describe 'when initializing' do
		it 'transforms json string into ruby array' do
			UrlsEntity.new(json:@json).array.must_equal @array
		end

    it 'leaves ruby array the same' do
      UrlsEntity.new(array:@array).array.must_equal @array
    end

    it 'creates blank array when no args' do
      UrlsEntity.new.array.must_equal []
    end

    it 'creates blank array when json arg is nil' do
      UrlsEntity.new(json:nil).array.must_equal []
    end

    it 'creates blank array when array arg is nil' do
      UrlsEntity.new(array:nil).array.must_equal []
    end

    it 'creates blank array when array arg is an empty string' do
      UrlsEntity.new(array:'').array.must_equal []
    end

    it 'creates blank array when json arg is an empty string' do
      UrlsEntity.new(json:'').array.must_equal []
    end
	end

  describe 'when removing by one value' do
    describe 'when only one item already present' do
      it 'removes matching key' do
        o = UrlsEntity.new array:@array
        o.remove_by [{url: @array.first['url']}]
        o.array.length.must_equal 0
      end
    end

    describe 'when many items present' do
      it 'removes only the matching key' do
        two_item_array = UrlsArrayFactory.new(2).array
        o              = UrlsEntity.new(array:two_item_array)
        sample         = two_item_array.sample
        o.remove_by [{sample.keys[0].to_sym => sample[sample.keys[0]]}]
        o.array.length.must_equal 1
      end
    end

    describe 'when no items present' do
      it 'has a blank array' do
        o = UrlsEntity.new
        o.remove_by [{title:'Map of Room'}]
        o.array.must_equal []
      end
    end
  end

  describe 'when removing by multiple values' do
    before do
      @three_item_array = UrlsArrayFactory.new(3).array
      @sample_1         = @three_item_array[0]
      @sample_2         = @three_item_array[1]
    end

    describe 'when keys have the same name' do
      it 'removes both values' do
        o = UrlsEntity.new(array:@three_item_array)
        o.remove_by([{@sample_1.keys[0].to_sym => @sample_1[@sample_1.keys[0]]}, {@sample_2.keys[0].to_sym => @sample_2[@sample_2.keys[0]]}])
        o.array.length.must_equal 1
      end
    end

    describe 'when keys have different names' do
      it 'removes both values' do
        o = UrlsEntity.new(array:@three_item_array)
        o.remove_by([{@sample_1.keys[1].to_sym => @sample_1[@sample_1.keys[1]]}, {@sample_2.keys[0].to_sym => @sample_2[@sample_2.keys[0]]}])
        o.array.length.must_equal 1
      end
    end
  end

  describe 'when adding items' do
    before do
      @sample_1 = UrlsArrayFactory.new(1).array
      @sample_2 = UrlsArrayFactory.new(1).array
      @sample_3 = UrlsArrayFactory.new(3).array
      @o = UrlsEntity.new array: @sample_1.dup
    end

    describe 'when ary being added has one new items' do
      it 'adds item to array' do
        @o.add @sample_2
        @o.array.must_equal @sample_1 + @sample_2
      end
    end

    describe 'when ary being added has three new items' do
      it 'adds all items to array' do
        @o.add @sample_3
        @o.array.must_equal @sample_1 + @sample_3
      end
    end

    describe 'when array already had items in ary' do
      it 'does not change the array' do
        @o.add @sample_1
        @o.array.must_equal @sample_1
      end
    end
  end

  describe 'when converting array to json' do
    it 'returns json string' do
      o = UrlsEntity.new array:@array
      o.json.must_be_kind_of String
    end
  end

  describe 'when requesting extension for mime' do
    it 'returns a string for found type' do
      UrlsEntity.extension('application/rtf').must_equal '.rtf'
    end
    it 'returns doc for not found type' do
      UrlsEntity.extension('non/sense').must_equal '.doc'
    end
  end

  describe 'for forcing urls to use full path' do
    describe 'when the urls were all relative' do
      it 'returns urls with full paths' do
        o = UrlsEntity.new array:@array
        o.force_urls_to_use_full_path
        o.array[0]['url'][0..25].must_equal UrlsEntity.root_domain
        ## doesnt enforce that it wont be this; write a validation and a new test with this if its important
        # o.array[0]['url'][27].wont_equal '/'
      end
    end

    describe 'when only some of the urls were require_relative' do
      it 'did not duplicate the root url' do
        o = UrlsEntity.new array: @array + [{'sf_id' => 234234, 'title' => "awfeawf wf", 'url' => "#{UrlsEntity.root_domain}/wefwef/wefwef.pdf", 'type' => '.pdf'}]
        o.force_urls_to_use_full_path
        o.array.each {|ary|
          ary['url'][0..25].must_equal UrlsEntity.root_domain
          ary['url'][26..51].wont_equal UrlsEntity.root_domain}
      end
    end

  end

end
