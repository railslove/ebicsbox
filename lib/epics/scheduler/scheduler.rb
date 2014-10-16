$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'json'
require 'epics/http'

module Clockwork
  QUEUE = Epics::Http::QUEUE.new
  handler { |job| QUEUE.publish 'sta', job }

  every(30.seconds, JSON.dump({refresh: "now"}))
end