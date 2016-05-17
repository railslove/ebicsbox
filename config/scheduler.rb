require_relative '../config/bootstrap'
require_relative '../box/queue'

module Clockwork
  # TODO: Make these configurable
  every(1.hours, "sta") { Box::Queue.fetch_account_statements }
  every(3.hours, "check.orders") { Box::Queue.update_processing_status }
end
