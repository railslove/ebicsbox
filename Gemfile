source 'https://rubygems.org'

# Specify your gem's dependencies in epics-http.gemspec
gemspec

gem 'pg', platform: :mri
gem 'thin', platform: :mri
gem 'jdbc-postgres', platform: :jruby
gem 'trinidad', "1.5.0.B1", platform: :jruby

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'database_cleaner'
  gem 'dotenv'
  gem 'rspec'
  gem 'guard-rspec', require: false
  gem 'airborne', '0.1.15'
  gem 'webmock'
end
