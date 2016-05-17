$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rack/cors'

# Load and run the app
require_relative './lib/epics/box'
require_relative './lib/epics/box/server'
require_relative './lib/epics/box/middleware/license_validator'
require_relative './lib/epics/box/middleware/connection_validator'

box = Rack::Builder.app do
  use Rack::CommonLogger if ENV['RACK_ENV'] == 'production'

  use Epics::Box::Middleware::LicenseValidator if ENV['REPLICATED_INTEGRATIONAPI']
  use Epics::Box::Middleware::ConnectionValidator, DB
  use Epics::Box.configuration.auth_provider

  use Rack::Cors do
    allow do
      origins '*'
      resource '*', :headers => :any, :methods => [:get, :post, :put, :delete, :options]
    end
  end


  map "/admin" do
    use Rack::Static, urls: [""], root: "public", index: "index.html"
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

  run Epics::Box::Server
end

run box
