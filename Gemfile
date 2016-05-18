source 'https://rubygems.org'

ruby '2.3.0', engine: 'jruby', engine_version: '9.1.0.0'

gem 'rake'
gem 'beaneater', '~> 1.0.0'
gem 'clockwork'
gem 'cmxl', git: 'https://github.com/railslove/cmxl.git'
gem 'camt_parser', git: 'https://github.com/railslove/camt_parser.git'
gem 'grape'
gem 'grape-entity', '0.4.8'
gem 'faraday'
gem 'jdbc-postgres'
gem 'nokogiri'
gem 'ruby-swagger'
gem 'sepa_king'
gem 'sequel'
gem 'puma'
gem 'jwt'
gem 'rack-cors', require: false

if ENV['EBICS_CLIENT'] == 'Blebics::Client'
  gem 'jruby-openssl', '0.8.2'
  gem 'blebics-wrapper', git: 'git@github.com:railslove/blebics-wrapper.git'
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
  gem 'pry'
end
