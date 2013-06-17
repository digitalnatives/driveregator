# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'driveregator/version'

Gem::Specification.new do |spec|
  spec.name          = "driveregator"
  spec.version       = Driveregator::VERSION
  spec.authors       = ["LuckyThirteen"]
  spec.email         = ["baloghzsof@gmail.com"]
  spec.summary       = %q{Command line tool for listing GoogleDrive permissons}
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_dependency "google-api-client"
  spec.add_dependency "launchy"
  spec.add_dependency "progress"
  spec.add_dependency "ya2yaml"
end