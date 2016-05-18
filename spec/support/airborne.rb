require 'airborne'

require_relative '../../box/middleware/static_authentication'
require_relative '../../box/apis/base'

Airborne.configure do |config|
  config.rack_app = Rack::Builder.app do
    use Box::Middleware::StaticAuthentication
    run Box::Apis::Base
  end
end
