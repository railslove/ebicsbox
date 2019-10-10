# frozen_string_literal: true

require 'rspec/expectations'

RSpec::Matchers.define :have_logged_message do |message|
  match do |actual|
    actual.call
    $box_logger.rewind
    if message.is_a?(Regexp)
      $box_logger.read =~ message
    else
      $box_logger.read.include?(message)
    end
  end

  supports_block_expectations

  failure_message do |_actual|
    "expected block to log the following message: '#{message}'"
  end
end
