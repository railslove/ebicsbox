require 'spec_helper'

module Epics
  module Box
    RSpec.describe Content do
      let(:organization) { Organization.create(name: 'Organization 1') }
      let(:account) { organization.add_account(name: 'Test', iban: 'TEST', mode: "Fake") }
      let!(:user) { User.create(organization_id: organization.id, name: 'Some user', access_token: 'orga-user') }
      let!(:another_user) { User.create(organization_id: organization.id, name: 'Another user') }

      describe 'POST /:iban/subscribers' do
        context 'user already has a subscriber for given account' do
          before { account.add_subscriber(user_id: user.id, remote_user_id: 'test123') }

          it 'fails with a 400' do
            post "/#{account.iban}/subscribers", { ebics_user: 'someuser' }, { 'Authorization' => "token #{user.access_token}" }
            expect(response.status).to eq(400)
          end

          it 'includes a meaningful message' do
            post "/#{account.iban}/subscribers", { ebics_user: 'someuser' }, { 'Authorization' => "token #{user.access_token}" }
            expect_json 'message', "This user already has a subscriber for this account."
          end
        end

        context 'another user has the same ebics user_id for that account' do
          before { account.add_subscriber(user_id: another_user.id, remote_user_id: 'test123') }

          it 'fails with a 400' do
            post "/#{account.iban}/subscribers", { ebics_user: 'test123' }, { 'Authorization' => "token #{user.access_token}" }
            expect(response.status).to eq(400)
          end

          it 'includes a meaningful message' do
            post "/#{account.iban}/subscribers", { ebics_user: 'test123' }, { 'Authorization' => "token #{user.access_token}" }
            expect_json 'message', "Another user is using the same EBICS user id."
          end
        end

        context 'some other error during setup' do
          it 'fails with a 400' do
            post "/#{account.iban}/subscribers", { ebics_user: 'test123' }, { 'Authorization' => "token #{user.access_token}" }
            expect(response.status).to eq(400)
          end
        end

        context 'user does not yet have a subscriber for given account' do
          it 'return success' do
            allow_any_instance_of(Account).to receive(:add_unique_subscriber).and_return(true)
            post "/#{account.iban}/subscribers", { ebics_user: 'someuser' }, { 'Authorization' => "token #{user.access_token}" }
            expect(response.status).to eq(201)
          end
        end
      end
    end
  end
end
