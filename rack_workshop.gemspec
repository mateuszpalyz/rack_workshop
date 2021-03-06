# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack_workshop/version'

Gem::Specification.new do |spec|
  spec.name          = "rack_workshop"
  spec.version       = RackWorkshop::VERSION
  spec.authors       = ["Mateusz Palyz"]
  spec.email         = ["m.palyz@pilot.co"]
  spec.summary       = %q{some middleware}
  spec.description   = %q{sooome middleware}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "timecop"
end
