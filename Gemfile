source 'https://rubygems.org'

if ENV['EBICS_CLIENT'] == 'Blebics::Client'
  ruby '2.2.2', engine: 'jruby', engine_version: '9.0.3.0'
else
  ruby '2.2.3', engine: 'jruby', engine_version: '9.0.5.0'
end

gem 'rake'
gem 'beaneater', '~> 1.0.0'
gem 'clockwork'
gem 'cmxl', git: 'https://github.com/railslove/cmxl.git'
gem 'grape'
gem 'grape-entity', '0.4.8'
gem 'faraday'
gem 'jdbc-postgres'
gem 'nokogiri'
gem 'pry'
gem 'ruby-swagger'
gem 'sepa_king'
gem 'sequel'
gem 'puma'

if ENV['EBICS_CLIENT'] == 'Blebics::Client'
  gem 'bouncy-castle-java', '1.5.0146.1'
  gem 'jruby-openssl', '0.8.2'
  gem 'blebics-wrapper', path: '../java-client'
else
  gem 'jruby-openssl', '0.9.13'
  gem 'epics', '~> 1.4.0'
end

group :development, :test do
  gem 'database_cleaner'
  gem 'dotenv'
  gem 'foreman'
  gem 'rspec'
  gem 'airborne'
  gem 'timecop'
  gem 'webmock'
end
