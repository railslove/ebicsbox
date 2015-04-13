$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'json'
require 'epics/box'

module Clockwork
  QUEUE = Epics::Box::QUEUE.new
  handler { |job| QUEUE.publish job, JSON.dump({do: :it}) }

  # every(5.minutes, "sta"))
  every(30.seconds, "check.orders")
end
