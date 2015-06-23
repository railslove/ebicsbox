require 'airborne'

Airborne.configure do |config|
  config.rack_app = Epics::Box::Server
end
