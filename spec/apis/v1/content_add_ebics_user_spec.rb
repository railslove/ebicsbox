require 'spec_helper'

require_relative '../../../box/apis/v1/content'

module Box
  RSpec.describe Apis::V1::Content do
    let(:organization) { Fabricate(:organization) }
    let(:account) { organization.add_account(name: 'Test', iban: 'TEST', mode: "Fake") }
    let!(:user) { User.create(organization_id: organization.id, name: 'Some user', access_token: 'orga-user') }
    let!(:another_user) { User.create(organization_id: organization.id, name: 'Another user') }

    describe 'POST /:iban/ebics_users' do
      context 'user already has a ebics_user for given account' do
        before { account.add_ebics_user(user_id: user.id, remote_user_id: 'test123') }

        it 'fails with a 400' do
          post "/#{account.iban}/ebics_users", { ebics_user: 'someuser' }, { 'Authorization' => "token #{user.access_token}" }
          expect(response.status).to eq(400)
        end

        it 'includes a meaningful message' do
          post "/#{account.iban}/ebics_users", { ebics_user: 'someuser' }, { 'Authorization' => "token #{user.access_token}" }
          expect_json 'message', "This user already has a ebics_user for this account."
        end
      end

      context 'another user has the same ebics user_id for that account' do
        before { account.add_ebics_user(user_id: another_user.id, remote_user_id: 'test123') }

        it 'fails with a 400' do
          post "/#{account.iban}/ebics_users", { ebics_user: 'test123' }, { 'Authorization' => "token #{user.access_token}" }
          expect(response.status).to eq(400)
        end

        it 'includes a meaningful message' do
          post "/#{account.iban}/ebics_users", { ebics_user: 'test123' }, { 'Authorization' => "token #{user.access_token}" }
          expect_json 'message', "Another user is using the same EBICS user id."
        end
      end

      context 'some other error during setup' do
        it 'fails with a 400' do
          post "/#{account.iban}/ebics_users", { ebics_user: 'test123' }, { 'Authorization' => "token #{user.access_token}" }
          expect(response.status).to eq(400)
        end
      end

      context 'user does not yet have a ebics_user for given account' do
        it 'return success' do
          allow_any_instance_of(Account).to receive(:add_unique_ebics_user).and_return(true)
          post "/#{account.iban}/ebics_users", { ebics_user: 'someuser' }, { 'Authorization' => "token #{user.access_token}" }
          expect(response.status).to eq(201)
        end
      end
    end
  end
end
