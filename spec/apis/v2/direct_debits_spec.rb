# frozen_string_literal: true

require 'spec_helper'

module Box
  RSpec.describe Apis::V2::DirectDebits do
    include_context 'valid user'
    include_context 'with account'

    DIRECT_DEBIT_TRANSFER_SPEC = {
      id: :string,
      account: :string,
      name: :string,
      iban: :string,
      bic: :string,
      amount_in_cents: :integer,
      end_to_end_reference: :string,
      status: :string,
      reference: :string,
      collection_date: :date,
      _links: :object
    }.freeze

    VALID_DEBIT_HEADERS = {
      'Accept' => 'application/vnd.ebicsbox-v2+json',
      'Authorization' => 'Bearer test-token'
    }.freeze

    INVALID_TOKEN_HEADER = {
      'Accept' => 'application/vnd.ebicsbox-v2+json',
      'Authorization' => 'Bearer invalid-token'
    }.freeze

    ###
    ### GET /direct debits
    ###

    describe 'GET: /direct_debits' do
      context 'when no valid access token is provided' do
        it 'returns a 401' do
          get '/direct_debits', INVALID_TOKEN_HEADER
          expect_status 401
        end
      end

      context 'when no debits are available' do
        it 'returns a 200' do
          get '/direct_debits', VALID_DEBIT_HEADERS
          expect_status 200
        end

        it 'returns an empty array' do
          get '/direct_debits', VALID_DEBIT_HEADERS
          expect_json []
        end
      end

      context 'when debits exist' do
        let!(:debit) { Fabricate(:debit, eref: 'my-debit', account_id: account.id) }

        it 'does not show debits from other organizations' do
          other_debit = Fabricate(:debit, account_id: account.id.succ)
          get '/direct_debits', VALID_DEBIT_HEADERS
          expect(json_body).to_not include(other_debit.eref)
        end

        it 'returns includes the existing direct debit' do
          get '/direct_debits', VALID_DEBIT_HEADERS
          expect(json_body.first[:end_to_end_reference]).to eql(debit.eref)
          expect(json_body.first[:iban]).to eql('AL90208110080000001039531801')
          expect(json_body.first[:account]).to eql(account.iban)
        end

        describe 'object format' do
          it 'exposes properly formatted data' do
            get '/direct_debits', VALID_DEBIT_HEADERS
            expect_json_types '0', DIRECT_DEBIT_TRANSFER_SPEC
          end
        end

        context 'when account filter is active' do
          let!(:second_account) { organization.add_account(name: 'Second account', iban: 'SECONDACCOUNT') }
          let!(:other_debit) { Fabricate(:debit, account_id: second_account.id, eref: 'other-debit') }

          let!(:third_account) { organization.add_account(name: 'Third account', iban: 'THIRDACCOUNT') }
          let!(:other_debit_2) { Fabricate(:debit, account_id: third_account.id, eref: 'other-debit-2') }

          it 'only returns transactions belonging to matching ibans' do
            get "/direct_debits?iban=#{account.iban}", VALID_DEBIT_HEADERS
            expect_json_sizes 1
            expect_json '0', end_to_end_reference: debit.eref
          end

          it 'does not return transactions not belonging to matching account' do
            get "/direct_debits?iban=#{second_account.iban}", VALID_DEBIT_HEADERS
            expect_json_sizes 1
            expect_json '0', end_to_end_reference: other_debit.eref
          end

          it 'allows to specify multiple accounts' do
            get "/direct_debits?iban[]=#{account.iban}&iban[]=#{second_account.iban}", VALID_DEBIT_HEADERS
            expect_json_sizes 2
          end
        end

        describe 'pagination' do
          before { Box::Transaction.dataset.destroy }

          let!(:debit_old) { Fabricate(:debit, eref: 'debit-old', account_id: account.id) }
          let!(:debit_new) { Fabricate(:debit, eref: 'debit-new', account_id: account.id) }

          it 'returns multiple items by default' do
            get '/direct_debits', VALID_DEBIT_HEADERS
            expect_json_sizes 2
          end

          it 'orders by name' do
            get '/direct_debits', VALID_DEBIT_HEADERS
            expect_json '0', end_to_end_reference: 'debit-new'
            expect_json '1', end_to_end_reference: 'debit-old'
          end

          it 'allows to specify items per page' do
            get '/direct_debits?per_page=1', VALID_DEBIT_HEADERS
            expect_json_sizes 1
          end

          it 'allows to specify the page' do
            get '/direct_debits?page=1&per_page=1', VALID_DEBIT_HEADERS
            expect_json '0', end_to_end_reference: 'debit-new'

            get '/direct_debits?page=2&per_page=1', VALID_DEBIT_HEADERS
            expect_json '0', end_to_end_reference: 'debit-old'
          end

          it 'sets pagination headers' do
            get '/direct_debits?per_page=1', VALID_DEBIT_HEADERS
            expect(headers['Link']).to include("rel='next'")
          end
        end
      end
    end

    ###
    ### POST /accounts
    ###

    describe 'POST: /direct_debits' do
      let!(:account) { Fabricate(:activated_account, organization_id: organization.id, name: 'My test account', iban: 'DE75374497411708271691', bic: 'GENODEF1NDH') }
      let(:valid_attributes) do
        {
          account: account.iban,
          name: 'Max Mustermann',
          iban: 'DE75374497411708271691',
          bic: 'GENODEF1NDH',
          amount_in_cents: 123_45,
          end_to_end_reference: 'valid-debit-ref',
          mandate_id: 'FooBar',
          mandate_signature_date: 2.days.ago.to_i
        }
      end

      context 'when no valid access token is provided' do
        it 'returns a 401' do
          post '/direct_debits', {}, INVALID_TOKEN_HEADER
          expect_status 401
        end
      end

      context 'invalid data' do
        it 'returns a 401' do
          post '/direct_debits', {}, VALID_DEBIT_HEADERS
          expect_status 400
        end

        it 'specifies invalid fields' do
          post '/direct_debits', {}, VALID_DEBIT_HEADERS
          expect_json_types errors: {
            account: :array_of_strings,
            name: :array_of_strings,
            iban: :array_of_strings,
            bic: :array_or_null,
            amount_in_cents: :array_of_strings,
            end_to_end_reference: :array_of_strings,
            mandate_id: :array_of_strings,
            mandate_signature_date: :array_of_strings
          }
        end

        it 'provides a proper error message' do
          post '/direct_debits', {}, VALID_DEBIT_HEADERS
          expect_json message: "Validation of your request's payload failed!"
        end

        it 'does not allow two debits with the same end_to_end_reference for one account' do
          debit = Fabricate(:debit, account_id: account.id, eref: 'my-debit-eref')
          post '/direct_debits', { account: account.iban, end_to_end_reference: 'my-debit-eref' }, VALID_DEBIT_HEADERS
          expect_json 'errors.end_to_end_reference', ['must be unique']
        end

        it 'allows a max length of 140 characters for reference' do
          post '/direct_debits', { reference: 'a' * 141 }, VALID_DEBIT_HEADERS
          expect_json 'errors.reference', ['must be at the most 140 characters long']
        end

        it 'fails on invalid IBAN' do
          post '/direct_debits', valid_attributes.merge(iban: 'MYTESTIBAN'), VALID_DEBIT_HEADERS
          expect_json message: 'Failed to initiate direct debit.', errors: { base: 'Iban MYTESTIBAN is invalid' }
        end

        it 'fails on invalid BIC' do
          post '/direct_debits', valid_attributes.merge(bic: 'MYTESTBIC'), VALID_DEBIT_HEADERS
          expect_json message: 'Failed to initiate direct debit.', errors: { base: 'Bic MYTESTBIC is invalid' }
        end
      end

      context 'valid data' do
        it 'returns a 201' do
          post '/direct_debits', valid_attributes, VALID_DEBIT_HEADERS
          expect_status 201
        end

        it 'returns a proper message' do
          post '/direct_debits', valid_attributes, VALID_DEBIT_HEADERS
          expect_json 'message', 'Direct debit has been initiated successfully!'
        end

        it 'triggers a debit transfer' do
          expect(DirectDebit).to receive(:create!)
          post '/direct_debits', valid_attributes, VALID_DEBIT_HEADERS
        end

        it 'triggers a debit transfer without bic' do
          expect(DirectDebit).to receive(:create!)
          post '/direct_debits', valid_attributes.reject { |k, _| k == :bic }, VALID_DEBIT_HEADERS
        end

        it 'transforms parameters so they are understood by debit business process' do
          expect(DirectDebit).to receive(:create!).with(account, anything, user)
          post '/direct_debits', valid_attributes, VALID_DEBIT_HEADERS
        end

        it 'allows same end_to_end_reference for two different accounts' do
          other_account = Fabricate(:account, organization_id: account.organization_id, iban: 'DE41405327214540168131')
          debit = Fabricate(:debit, account_id: other_account.id, eref: 'my-debit-eref')
          post '/direct_debits', valid_attributes.merge(end_to_end_reference: 'my-debit-eref'), VALID_DEBIT_HEADERS
          expect_status 201
        end
      end
    end

    ###
    ### GET /accounts
    ###

    describe 'GET: /direct_debits/:id' do
      context 'when no valid access token is provided' do
        it 'returns a 401' do
          get '/direct_debits/1', INVALID_TOKEN_HEADER
          expect_status 401
        end
      end

      context 'when direct debit does not exist' do
        context 'when invalid uuid' do
          it 'returns a 404' do
            get '/direct_debits/UNKNOWN_ID', VALID_DEBIT_HEADERS
            expect_status 404
          end
        end

        context 'when uuid does not exist' do
          it 'returns a 404' do
            get '/direct_debits/d23d5d52-28fc-4352-a094-b69818a3fdf1', VALID_DEBIT_HEADERS
            expect_status 404
          end
        end
      end

      context 'when direct debit does exist' do
        let!(:debit) { Fabricate(:debit, eref: 'my-debit', account_id: account.id) }

        it 'returns a 200' do
          id = debit.public_id
          get "/direct_debits/#{id}", VALID_DEBIT_HEADERS
          expect_status 200
        end

        it 'exposes properly formatted data' do
          get "/direct_debits/#{debit.public_id}", VALID_DEBIT_HEADERS
          expect_json_types DIRECT_DEBIT_TRANSFER_SPEC
        end
      end
    end
  end
end
