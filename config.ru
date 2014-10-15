$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

Bundler.require

# Load and run the app
require File.expand_path(File.dirname(__FILE__) + '/lib/epics/http.rb')

run Epics::Http::Server