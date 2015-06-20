$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

Bundler.require

# Load and run the app
require File.expand_path(File.dirname(__FILE__) + '/lib/epics/box.rb')

box = Rack::Builder.app do
  use Rack::Auth::Basic, "Protected Area" do |username, password|
    username == ENV['USERNAME'] && password == ENV['PASSWORD']
  end if ENV['USERNAME'] && ENV['PASSWORD']

  use Epics::Box::SequelConnectionValidator, DB
  run Epics::Box::Server
end

run box
