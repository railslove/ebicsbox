require 'airborne'

RSpec.shared_context "valid user" do
  let!(:organization) { Epics::Box::Organization.create(name: 'Test Organization') }
  let!(:user) { Epics::Box::User.create(organization_id: organization.id, name: 'Test User', access_token: 'test-token') }
end
