# frozen_string_literal: true

require_relative "config/bootstrap"
require 'sidekiq/web'

if ENV["SENTRY_DSN"]
  require "sentry-ruby"
  Sentry.init do |config|
    # Raven reports on the following environments
    config.enabled_environments = %w[development staging production]
  end

  use Sentry::Rack::CaptureExceptions
end

if ENV["ROLLBAR_ACCESS_TOKEN"]
  require "rollbar/middleware/rack"
  Rollbar.configure do |config|
    config.access_token = ENV["ROLLBAR_ACCESS_TOKEN"]
    config.environment = ENV["RACK_ENV"]
  end

  use Rollbar::Middleware::Rack
end

if ENV["RACK_ENV"] == "production"
  unless ENV["DISABLE_SSL_FORCE"]
    require "rack/ssl-enforcer"
    use Rack::SslEnforcer, except: ["/health", "/setup"]
  end

  # Log all requests in apache log file format
  use Rack::CommonLogger
end

# check env vars
Box.configuration.valid?

# Load database connection validator middleware
require_relative "box/middleware/connection_validator"
use Box::Middleware::ConnectionValidator, DB

# Load authentication middleware
use Box.configuration.auth_provider

# Enable CORS to enable access to our API from frontend apps and our swagger documentation
require "rack/cors"
use Rack::Cors do
  allow do
    origins "*"
    resource "*", headers: :any, methods: [:get, :post, :put, :delete, :options]
  end
end

use Rack::Session::Cookie, secret: ENV['SESSION_SECRET'] || 'your_secret_key'

# Deliver assets
use Rack::Static, urls: [
  "/swagger-ui-standalone-preset.js",
  "/swagger-ui-bundle.js",
  "/swagger-ui-standalone-preset.js",
  "/swagger-ui.css",
  "/swagger-ui.js",
  "/doc/swagger-v1.json",
  "/doc/swagger-v2.json"
], root: "public/swagger"

# Deliver html/json documentation template
map "/docs" do
  run lambda { |env|
    [
      200,
      {
        "Content-Type" => "text/html",
        "Cache-Control" => "public, max-age=86400"
      },
      File.open("public/swagger/index.html", File::RDONLY)
    ]
  }
end

map '/sidekiq' do
  run Sidekiq::Web
end

# Finally, load application and all its endpoints
require_relative "box/apis/base"
run Box::Apis::Base
