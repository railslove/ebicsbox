$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'json'
require 'epics/box'

module Clockwork
  # TODO: Make these configurable
  every(5.minutes, "sta") { Epics::Box::Queue.fetch_account_statements }
  every(3.hours, "check.orders") { Epics::Box::Queue.check_accounts }
end
