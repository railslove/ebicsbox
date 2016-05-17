require 'airborne'

require_relative '../../lib/epics/box/middleware/static_authentication'
require_relative '../../lib/epics/box/server'

Airborne.configure do |config|
  config.rack_app = Rack::Builder.app do
    use Epics::Box::Middleware::StaticAuthentication
    run Epics::Box::Server
  end
end
