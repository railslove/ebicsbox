# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'epics/http/version'

Gem::Specification.new do |spec|
  spec.name          = "epics-http"
  spec.version       = Epics::Http::VERSION
  spec.authors       = ["Lars Brillert"]
  spec.email         = ["lars@railslove.com"]
  spec.summary       = %q{Epics Http Endpoint}
  spec.description   = %q{Epics Http Endpoint}
  spec.homepage      = ""

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "grape"
  spec.add_dependency "clockwork"
  spec.add_dependency "redis"
  spec.add_dependency "httparty"
  spec.add_dependency "beaneater"
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
