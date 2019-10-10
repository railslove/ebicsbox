# frozen_string_literal: true

require 'spec_helper'

module Box
  RSpec.describe Apis::V2::Management::Accounts do
    include_context 'admin user'

    let(:other_organization) { Fabricate(:organization) }

    describe 'POST /accounts' do
      context 'invalid body' do
        before { post 'management/accounts', {}, TestHelpers::VALID_HEADERS }

        it 'rejects empty posts' do
          expect_status 400
        end

        it 'contains a meaningful message' do
          expect_json 'message', "Validation of your request's payload failed!"
        end

        it 'highlights missing fields' do
          expect_json 'errors',
                      name: ['is missing', 'is empty'],
                      iban: ['is missing', 'is empty'],
                      bic: ['is missing', 'is empty']
        end
      end

      context 'valid body' do
        def do_request
          post 'management/accounts', { name: 'Test account', iban: 'my-iban', bic: 'my-iban' }, TestHelpers::VALID_HEADERS
        end

        it 'stores new minimal accounts' do
          expect { do_request }.to change(Account, :count)
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

      context 'no account with given IBAN exist' do
        it 'returns an error' do
          get 'management/accounts/NOTEXISTING', TestHelpers::VALID_HEADERS
          expect_status 404
        end

        it 'returns a proper error message' do
          get 'management/accounts/NOTEXISTING', TestHelpers::VALID_HEADERS
          expect_json 'message', 'Your organization does not have an account with given IBAN!'
        end
      end

      context 'account with given IBAN belongs to another organization' do
        it 'denies updates to inaccesible accounts' do
          get "management/accounts/#{other_account.iban}", TestHelpers::VALID_HEADERS
          expect_status 404
        end

        it 'returns a proper error message' do
          get "management/accounts/#{other_account.iban}", TestHelpers::VALID_HEADERS
          expect_json 'message', 'Your organization does not have an account with given IBAN!'
        end
      end
    end

    describe 'PUT /accounts/:id' do
      let(:account) { Account.create(name: 'name', iban: 'old-iban', bic: 'old-bic', organization_id: organization.id) }
      let(:other_account) { Account.create(name: 'name', iban: 'iban-2', bic: 'bic-2', organization_id: other_organization.id) }

      context 'no account with given IBAN exist' do
        it 'returns an error' do
          put 'management/accounts/NOTEXISTING', {}, TestHelpers::VALID_HEADERS
          expect_status 404
        end

        it 'returns a proper error message' do
          put 'management/accounts/NOTEXISTING', {}, TestHelpers::VALID_HEADERS
          expect_json 'message', 'Your organization does not have an account with given IBAN!'
        end
      end

      context 'account with given IBAN belongs to another organization' do
        it 'denies updates to inaccesible accounts' do
          put "management/accounts/#{other_account.iban}", {}, TestHelpers::VALID_HEADERS
          expect_status 404
        end

        it 'returns a proper error message' do
          put "management/accounts/#{other_account.iban}", {}, TestHelpers::VALID_HEADERS
          expect_json 'message', 'Your organization does not have an account with given IBAN!'
        end
      end

      context 'activated account' do
        before { account.add_ebics_user(activated_at: 1.hour.ago) }

        it 'cannot change iban' do
          expect do
            put "management/accounts/#{account.iban}", { iban: 'new-iban' }, TestHelpers::VALID_HEADERS
          end.to_not(change { account.reload.iban })
        end

        it 'cannot change bic' do
          expect do
            put "management/accounts/#{account.iban}", { bic: 'new-bic' }, TestHelpers::VALID_HEADERS
          end.to_not(change { account.reload.bic })
        end

        it 'ignores iban if it did not change' do
          put "management/accounts/#{account.iban}", { iban: 'old-iban', name: 'new name' }, TestHelpers::VALID_HEADERS

          expect(account.reload.name).to eql('new name')
        end

        it 'ignores the access_token attribute' do
          put "management/accounts/#{account.iban}", { iban: 'old-iban', name: 'new name', access_token: user.access_token }, TestHelpers::VALID_HEADERS

          expect(account.reload.name).to eql('new name')
        end
      end
    end
  end
end
