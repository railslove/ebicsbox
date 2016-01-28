$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'json'
require_relative '../init'

module Clockwork
  # TODO: Make these configurable
  every(6.hours, "sta") { Box::Queue.fetch_account_statements }
  every(3.hours, "check.orders") { Box::Queue.update_processing_status }
end
