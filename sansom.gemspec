# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "sansom"
  spec.version       = "0.0.3"
  spec.authors       = ["Nathaniel Symer"]
  spec.email         = ["nate@natesymer.com"]
  spec.summary       = "Flexible, versatile, light web framework named after Sansom street in Philly."
  spec.description   = s.summary + "It's under 140 lines of code & and it's lightning fast. It uses tree-based route resolution."
  spec.homepage      = "http://github.com/fhsjaagshs/sansom"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
end
