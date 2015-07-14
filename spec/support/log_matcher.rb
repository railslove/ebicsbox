require 'rspec/expectations'

RSpec::Matchers.define :have_logged_message do |message|
  match do |actual|
    actual.call
    $box_logger.rewind
    $box_logger.read.include?(message)
  end

  supports_block_expectations

  failure_message do |actual|
    "expected block to log the following message: '#{message}'"
  end
end
