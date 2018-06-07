module TestHelpers
  UUID_REGEXP = /[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/

  VALID_HEADERS = {
    'Accept' => 'application/vnd.ebicsbox-v2+json',
    'Authorization' => 'Bearer test-token'
  }

  INVALID_TOKEN_HEADER = {
    'Accept' => 'application/vnd.ebicsbox-v2+json',
    'Authorization' => 'Bearer invalid-token'
  }
end
