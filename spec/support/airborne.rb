require 'airborne'

require_relative '../../box/middleware/static_authentication'
require_relative '../../box/server'

Airborne.configure do |config|
  config.rack_app = Rack::Builder.app do
    use Box::Middleware::StaticAuthentication
    run Box::Server
  end
end
