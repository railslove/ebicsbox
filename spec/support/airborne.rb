require 'airborne'
require_relative '../../box/api'

Airborne.configure do |config|
  config.rack_app = Box::Api
end
