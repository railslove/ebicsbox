source 'https://rubygems.org'

ruby '2.3.1'

gem 'rake'
gem 'beaneater', '~> 1.0.0'
gem 'clockwork'
gem 'cmxl', git: 'https://github.com/railslove/cmxl.git'
gem 'camt_parser', git: 'https://github.com/railslove/camt_parser.git'
gem 'grape'
gem 'grape-entity', '0.4.8'
gem 'faraday'
gem 'nokogiri'
gem 'ruby-swagger'
gem 'sepa_king'
gem 'sequel'
gem 'puma'
gem 'jwt'
gem 'rack-cors', require: false

if ENV['EBICS_CLIENT'] == 'Blebics::Client'
  gem 'jdbc-postgres'
  gem 'jruby-openssl', '0.8.2'
  gem 'blebics-wrapper', git: 'git@github.com:railslove/blebics-wrapper.git'
else
  gem 'pg'
  gem 'byebug'
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
  gem 'fabrication'
  gem 'faker'
end
