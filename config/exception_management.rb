return if ENV['RACK_ENV'] != 'production'

if ENV['SENTRY_DSN']
  require 'sentry-raven'
  use Raven::Rack
end

if ENV['ROLLBAR_ACCESS_TOKEN']
  require 'rollbar/middleware/rack'
  Rollbar.configure do |config|
    config.access_token = ENV['ROLLBAR_ACCESS_TOKEN']
  end

  use Rollbar::Middleware::Rack
end