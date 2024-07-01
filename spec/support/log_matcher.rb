# frozen_string_literal: true

require "rspec/expectations"

RSpec::Matchers.define :have_logged_message do |message|
  match do |actual|
    actual.call
    $box_logger.rewind # rubocop:disable Style/GlobalVars
    if message.is_a?(Regexp)
      $box_logger.read =~ message # rubocop:disable Style/GlobalVars
    else
      $box_logger.read.include?(message) # rubocop:disable Style/GlobalVars
    end
  end

  supports_block_expectations

  failure_message do |_actual|
    "expected block to log the following message: '#{message}'"
  end
end
