if ENV['RACK_ENV'] == 'production'
  if ENV['SENTRY_DSN']
    require 'raven'
    use Raven::Rack
  end

  if ENV['ROLLBAR_ACCESS_TOKEN']
    Rollbar.configure do |config|
      config.access_token = ENV['ROLLBAR_ACCESS_TOKEN']
    end

    require 'rollbar/middleware/rack'
    use Rollbar::Middleware::Rack
  end
end