# -*- encoding: utf-8 -*-
# stub: blebics-wrapper 0.1.0 java lib

Gem::Specification.new do |s|
  s.name = "blebics-wrapper"
  s.version = "0.1.0"
  s.platform = "java"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "TODO: Set to 'http://mygemserver.com'" } if s.respond_to? :metadata=
  s.require_paths = ["lib"]
  s.authors = ["Johannes Heck"]
  s.bindir = "exe"
  s.date = "2016-02-16"
  s.description = "Wrapping all the ebics out of blebics"
  s.email = ["johannes@railslove.com"]
  s.files = [".gitignore", ".rspec", ".travis.yml", "Gemfile", "README.md", "Rakefile", "bin/console", "bin/setup", "blebics.gemspec", "lib/blebics-2.4.14.jar", "lib/blebics.rb", "lib/blebics/client.rb", "lib/blebics/distributed_electronic_signature.rb", "lib/blebics/letter_helper.rb", "lib/blebics/password_callback.rb", "lib/blebics/pem_converter.rb", "lib/blebics/user.rb", "lib/blebics/version.rb", "lib/letter/ini.erb"]
  s.homepage = "https://www.railslove.com/"
  s.rubygems_version = "2.4.8"
  s.summary = "Wrapping all the ebics out of blebics"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.10"])
      s.add_development_dependency(%q<rake>, ["~> 10.0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.10"])
      s.add_dependency(%q<rake>, ["~> 10.0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.10"])
    s.add_dependency(%q<rake>, ["~> 10.0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
