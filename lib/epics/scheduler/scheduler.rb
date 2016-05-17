require 'json'
require_relative '../box'

module Clockwork
  # TODO: Make these configurable
  every(1.hours, "sta") { Epics::Box::Queue.fetch_account_statements }
  every(3.hours, "check.orders") { Epics::Box::Queue.update_processing_status }
end
