$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'json'
require 'epics/box'

module Clockwork
  QUEUE = Epics::Box::QUEUE.new

  every(5.minutes, "sta") { QUEUE.publish('sta', {account_ids: Epics::Box::Account.all.map(&:id)} ) }
  every(3.hours, "check.orders") { QUEUE.publish('check.orders', {account_ids: Epics::Box::Account.all.map(&:id)} ) }
end
