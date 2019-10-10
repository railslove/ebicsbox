# frozen_string_literal: true

module TestHelpers
  UUID_REGEXP = /[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/.freeze

  VALID_HEADERS = {
    'Accept' => 'application/vnd.ebicsbox-v2+json',
    'Authorization' => 'Bearer test-token'
  }.freeze

  INVALID_TOKEN_HEADER = {
    'Accept' => 'application/vnd.ebicsbox-v2+json',
    'Authorization' => 'Bearer invalid-token'
  }.freeze
end
