$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'json'
require 'epics/box'

module Clockwork
  QUEUE = Epics::Box::QUEUE.new
  handler { |job| QUEUE.publish 'sta', job }

  every(30.seconds, JSON.dump({refresh: "now"}))
end