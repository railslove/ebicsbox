$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

# Load and run the app
require_relative './box/init'

# Load dependencies
require_relative './box/api'
require_relative './box/middleware/license_validator'
require_relative './box/middleware/connection_validator'

box = Rack::Builder.app do
  use Rack::CommonLogger if ENV['RACK_ENV']=='production'

  use Box::Middleware::LicenseValidator if ENV['REPLICATED_INTEGRATIONAPI']
  use Box::Middleware::ConnectionValidator, DB

  map "/admin" do
    use Rack::Static, urls: [""], root: "public", index: "index.html"
  end

  use Rack::Static, urls: ["/images", "/lib", "/fonts", "/js", "/css", "/swagger-ui.js"], root: "public/swagger"
  use Rack::Static, urls: ["/swagger.json"], root: "doc/swagger"

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

  run Box::Api
end

run box
