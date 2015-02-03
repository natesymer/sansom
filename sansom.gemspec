# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name          = "sansom"
  s.version       = "0.3.0"
  s.authors       = ["Nathaniel Symer"]
  s.email         = ["nate@natesymer.com"]
  s.summary       = "Scientific, philosophical, abstract web 'picowork' named after Sansom street in Philly, near where it was made."
  s.description   = s.summary + " " + "It's under 200 lines of code & it's lightning fast. It uses tree-based route resolution."
  s.homepage      = "http://github.com/fhsjaagshs/sansom"
  s.license       = "MIT"

  allfiles = `git ls-files -z`.split("\x0")
  s.files         = allfiles.grep(%r{(^[^\/]*$|^lib\/)}) # Match all lib files AND files in the root
  s.executables   = allfiles.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = allfiles.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", "~> 1.6"
  s.add_dependency "rack", "~> 1"
end
