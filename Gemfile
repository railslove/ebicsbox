source 'https://rubygems.org'

gem 'rake'
gem 'beaneater', '~> 1.0.0'
gem 'clockwork'
gem 'cmxl'
gem 'epics', branch: 'proxy_server'
gem 'grape'
gem 'grape-entity'
gem 'httparty'
gem 'nokogiri'
gem 'ruby-swagger'
gem 'sepa_king'
gem 'sequel'
gem 'sinatra'

platforms :mri do
  gem 'pg'
  gem 'thin'
end

platforms :jruby do
  gem 'jdbc-postgres'
  gem 'jruby-openssl'
  gem 'trinidad', "1.5.0.B1"
end

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'database_cleaner'
  gem 'dotenv'
  gem 'rspec'
  gem 'guard-rspec', require: false
  gem 'airborne', '0.1.15'
  gem 'timecop'
  gem 'webmock'
end
