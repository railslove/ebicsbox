source 'https://rubygems.org'

gem 'rake'
gem 'activesupport'
gem 'beaneater', '~> 1.0.0'
gem 'clockwork'
gem 'cmxl'
gem 'camt_parser', git: 'https://github.com/railslove/camt_parser.git'
gem 'grape'
gem 'grape-entity'
gem 'grape-swagger'
gem 'grape-swagger-entity'
gem 'faraday'
gem 'nokogiri'
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
  gem 'epics', '~> 1.5.0'
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
