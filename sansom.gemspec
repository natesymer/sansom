# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name          = "sansom"
  s.version       = "0.0.5"
  s.authors       = ["Nathaniel Symer"]
  s.email         = ["nate@natesymer.com"]
  s.summary       = "Flexible, versatile, light web framework named after Sansom street in Philly."
  s.description   = s.summary + "It's under 140 lines of code & and it's lightning fast. It uses tree-based route resolution."
  s.homepage      = "http://github.com/fhsjaagshs/sansom"
  s.license       = "MIT"

  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", "~> 1.6"
  s.add_dependency "rack", "~> 1"
end
