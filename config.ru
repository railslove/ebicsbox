$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

# Bundler.require

# Load and run the app
require File.expand_path(File.dirname(__FILE__) + '/lib/epics/box.rb')
require File.expand_path(File.dirname(__FILE__) + '/lib/epics/box/middleware/license_validator.rb')
require File.expand_path(File.dirname(__FILE__) + '/lib/epics/box/middleware/connection_validator.rb')

box = Rack::Builder.app do
  use Rack::CommonLogger if ENV['RACK_ENV']=='production'
  use Rack::Auth::Basic, "Protected Area" do |username, password|
    username == ENV['USERNAME'] && password == ENV['PASSWORD']
  end if ENV['USERNAME'] && ENV['PASSWORD']

  use Epics::Box::Middleware::LicenseValidator if ENV['REPLICATED_INTEGRATIONAPI']
  use Epics::Box::Middleware::ConnectionValidator, DB

  map "/admin" do
    use Rack::Static, urls: [""], root: "public", index: "index.html"
  end

  run Epics::Box::Server
end

run box
