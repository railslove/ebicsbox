require 'spec_helper'

module Box
  RSpec.describe Apis::V2::Management do
    include_context 'valid user'

    let(:organization) { Fabricate(:organization) }
    let(:other_organization) { Fabricate(:organization) }
    let(:user) { User.create(organization_id: organization.id, name: 'Some user', access_token: 'orga-user', admin: true) }

    VALID_HEADERS = {
      'Accept' => 'application/vnd.ebicsbox-v2+json'
    }

    describe 'POST /accounts' do
      context 'invalid body' do
        before { post 'management/accounts', {}, VALID_HEADERS.merge('Authorization' => "Bearer #{user.access_token}") }

        it 'rejects empty posts' do
          expect_status 400
        end

        it 'contains a meaningful message' do
          expect_json 'message', "Validation of your request's payload failed!"
        end

        it 'highlights missing fields' do
          expect_json 'errors', {
            name: ["is missing", "is empty"],
            iban: ["is missing", "is empty"],
            bic: ["is missing", "is empty"],
          }
        end
      end

      context 'valid body' do
        def do_request
          post 'management/accounts', { name: 'Test account', iban: 'my-iban', bic: 'my-iban' }, VALID_HEADERS.merge('Authorization' => "Bearer #{user.access_token}")
        end

        it 'stores new minimal accounts' do
          expect { do_request }.to change { Account.count }
        end

        it 'returns a 201 status' do
          do_request
          expect(response.status).to eq(201)
        end
      end
    end

    describe 'GET /accounts/:id' do
      let(:account) { Account.create(name: 'name', iban: 'old-iban', bic: 'old-bic', organization_id: organization.id) }
      let(:other_account) { Account.create(name: 'name', iban: 'iban-2', bic: 'bic-2', organization_id: other_organization.id) }

      before { user }

      context 'no account with given IBAN exist' do
        it 'returns an error' do
          get "management/accounts/NOTEXISTING", VALID_HEADERS.merge('Authorization' => "Bearer #{user.access_token}")
          expect_status 400
        end

        it 'returns a proper error message' do
          get "management/accounts/NOTEXISTING", VALID_HEADERS.merge('Authorization' => "Bearer #{user.access_token}")
          expect_json 'message', 'Your organization does not have an account with given IBAN!'
        end
      end

      context 'account with given IBAN belongs to another organization' do
        it 'denies updates to inaccesible accounts' do
          get "management/accounts/#{other_account.iban}", VALID_HEADERS.merge('Authorization' => "Bearer #{user.access_token}")
          expect_status 400
        end

        it 'returns a proper error message' do
          get "management/accounts/#{other_account.iban}", VALID_HEADERS.merge('Authorization' => "Bearer #{user.access_token}")
          expect_json 'message', 'Your organization does not have an account with given IBAN!'
        end
      end
    end

    describe 'PUT /accounts/:id' do
      let(:account) { Account.create(name: 'name', iban: 'old-iban', bic: 'old-bic', organization_id: organization.id) }
      let(:other_account) { Account.create(name: 'name', iban: 'iban-2', bic: 'bic-2', organization_id: other_organization.id) }

      before { user }

      context 'no account with given IBAN exist' do
        it 'returns an error' do
          put "management/accounts/NOTEXISTING", {}, VALID_HEADERS.merge('Authorization' => "Bearer #{user.access_token}")
          expect_status 400
        end

        it 'returns a proper error message' do
          put "management/accounts/NOTEXISTING", {}, VALID_HEADERS.merge('Authorization' => "Bearer #{user.access_token}")
          expect_json 'message', 'Your organization does not have an account with given IBAN!'
        end
      end

      context 'account with given IBAN belongs to another organization' do
        it 'denies updates to inaccesible accounts' do
          put "management/accounts/#{other_account.iban}", {}, VALID_HEADERS.merge('Authorization' => "Bearer #{user.access_token}")
          expect_status 400
        end

        it 'returns a proper error message' do
          put "management/accounts/#{other_account.iban}", {}, VALID_HEADERS.merge('Authorization' => "Bearer #{user.access_token}")
          expect_json 'message', 'Your organization does not have an account with given IBAN!'
        end
      end

      context 'activated account' do
        before { account.add_subscriber(activated_at: 1.hour.ago) }

        it 'cannot change iban' do
          expect { put "management/accounts/#{account.iban}", { iban: 'new-iban' }, VALID_HEADERS.merge('Authorization' => "Bearer #{user.access_token}") }.to_not change { account.reload.iban }
        end

        it 'cannot change bic' do
          expect { put "management/accounts/#{account.iban}", { bic: 'new-bic' }, VALID_HEADERS.merge('Authorization' => "Bearer #{user.access_token}") }.to_not change { account.reload.bic }
        end

        it 'ignores iban if it did not change' do
          expect { put "management/accounts/#{account.iban}", { iban: 'old-iban', name: 'new name' }, VALID_HEADERS.merge('Authorization' => "Bearer #{user.access_token}") }.to change { account.reload.name }
        end

        it 'ignores the access_token attribute' do
          expect { put "management/accounts/#{account.iban}", { iban: 'old-iban', name: 'new name', access_token: user.access_token } }.to change {
            account.reload.name }
        end
      end
    end
  end
end
