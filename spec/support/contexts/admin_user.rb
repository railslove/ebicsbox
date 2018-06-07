require 'airborne'

RSpec.shared_context "admin user" do
  let!(:organization) { Fabricate(:organization) }
  let!(:user) { Box::User.create(organization_id: organization.id, name: 'Test User', access_token: 'test-token', admin: true) }
end
