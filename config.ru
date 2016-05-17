require 'grape'
require 'rack/cors'

require_relative './config/bootstrap'

require_relative './box/apis/content'
require_relative './box/apis/management'
require_relative './box/apis/registration'
require_relative './box/apis/service'

require_relative './box/middleware/license_validator'
require_relative './box/middleware/connection_validator'


class AppServer < Grape::API
  mount Box::Apis::Service
  mount Box::Apis::Management
  mount Box::Apis::Content
  mount Box::Apis::Registration
end

box = Rack::Builder.app do
  use Rack::CommonLogger if ENV['RACK_ENV'] == 'production'

  use Box::Middleware::LicenseValidator if ENV['REPLICATED_INTEGRATIONAPI']
  use Box::Middleware::ConnectionValidator, DB
  use Box.configuration.auth_provider

  use Rack::Cors do
    allow do
      origins '*'
      resource '*', :headers => :any, :methods => [:get, :post, :put, :delete, :options]
    end
  end

  use Rack::Static, urls: ["/images", "/lib", "/fonts", "/js", "/css", "/swagger-ui.js"], root: "public/swagger"
  use Rack::Static, urls: ["/swagger.json"], root: "doc/swagger", header_rules: [
    [:all, {'Access-Control-Allow-Origin' => '*'}]
  ]

  map '/docs' do
    run lambda { |env|
      [
        200,
        {
          'Content-Type'  => 'text/html',
          'Cache-Control' => 'public, max-age=86400'
        },
        File.open('public/swagger/index.html', File::RDONLY)
      ]
    }
  end

  run AppServer
end

run box
