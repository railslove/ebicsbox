# frozen_string_literal: true

require 'airborne'

RSpec.shared_context 'valid user' do
  let!(:organization) { Fabricate(:organization) }
  let!(:user) { Box::User.create(organization_id: organization.id, name: 'Test User', access_token: 'test-token') }
end
