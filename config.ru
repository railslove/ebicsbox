$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

# Bundler.require

# Load and run the app
require File.expand_path(File.dirname(__FILE__) + '/lib/epics/box.rb')
require File.expand_path(File.dirname(__FILE__) + '/lib/epics/box/middleware/license_validator.rb')
require File.expand_path(File.dirname(__FILE__) + '/lib/epics/box/middleware/connection_validator.rb')

box = Rack::Builder.app do
  use Rack::CommonLogger if ENV['RACK_ENV']=='production'

  use Epics::Box::Middleware::LicenseValidator if ENV['REPLICATED_INTEGRATIONAPI']
  use Epics::Box::Middleware::ConnectionValidator, DB

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
