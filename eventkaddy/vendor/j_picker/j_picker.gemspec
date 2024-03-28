# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'j_picker/version'

Gem::Specification.new do |spec|
  spec.name          = "j_picker"
  spec.version       = JPicker::VERSION
  spec.authors       = ["EdwardMG"]
  spec.email         = ["edwardgallant@gmail.com"]
  spec.summary       = %q{jPicker for rails.}
  spec.description   = %q{jpicker-rails gem does not work, so rolled my own}
  spec.homepage      = ""
  spec.license       = "MIT"

	spec.files = Dir['lib/   *.rb'] + Dir['bin/*']
	spec.files += Dir['[A-Z]*'] + Dir['test/**/*']
	spec.files.reject! { |fn| fn.include? "CVS" }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
