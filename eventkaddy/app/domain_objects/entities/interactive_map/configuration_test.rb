require_relative './symlink'
require_relative './configuration'
require 'minitest/autorun'

describe InteractiveMap::Configuration do

  describe 'parse' do
    it 'returns a hash' do
      InteractiveMap::Configuration.new(InteractiveMap::Symlink).hash.must_be_kind_of Hash
    end

    it 'raises on nonexistent symlink' do
      proc { InteractiveMap::Configuration.new('./nonexistent_path').hash }.must_raise RuntimeError
    end
  end
end
