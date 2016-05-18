require 'airborne'

RSpec.shared_context "valid user" do
  let!(:organization) { Box::Organization.create(name: 'Test Organization') }
  let!(:user) { Box::User.create(organization_id: organization.id, name: 'Test User', access_token: 'test-token') }
end
