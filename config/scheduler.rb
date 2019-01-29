require_relative '../config/bootstrap'
require_relative '../box/queue'

UPDATE_BANK_STATEMENTS_INTERVAL = ENV['UPDATE_BANK_STATEMENTS_INTERVAL'] || 60
UPDATE_PROCESSING_STATUS_INTERVAL = ENV['UPDATE_PROCESSING_STATUS_INTERVAL'] || 300

module Clockwork
  every(UPDATE_BANK_STATEMENTS_INTERVAL.to_i * 60, "sta") {
    Box::Queue.fetch_account_statements
  }

  every(UPDATE_PROCESSING_STATUS_INTERVAL.to_i * 60, "check.orders") {
    Box::Queue.update_processing_status
  }
end