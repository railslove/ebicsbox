require 'spec_helper'

module Box
  RSpec.describe Apis::V2::CreditTransfers do
    include_context 'valid user'
    include_context 'with account'

    TRANSFER_SPEC = {

    }

    VALID_HEADERS = {
      'Accept' => 'application/vnd.ebicsbox-v2+json',
      'Authorization' => 'Bearer test-token'
    }

    INVALID_TOKEN_HEADER = {
      'Accept' => 'application/vnd.ebicsbox-v2+json',
      'Authorization' => 'Bearer invalid-token'
    }

    ###
    ### GET /accounts
    ###

    describe 'GET: /credit_transfers' do
      context "when no valid access token is provided" do
        it 'returns a 401' do
          get '/credit_transfers', INVALID_TOKEN_HEADER
          expect_status 401
        end
      end

      context "when no credits are available" do
        it 'returns a 200' do
          get '/credit_transfers', VALID_HEADERS
          expect_status 200
        end

        it 'returns an empty array' do
          get '/credit_transfers', VALID_HEADERS
          expect_json []
        end
      end

      context 'when credits exist' do
        let!(:credit) { Fabricate(:credit, eref: 'my-credit', account_id: account.id) }

        it 'does not show credits from other organizations' do
          other_organization = Fabricate(:organization)
          other_credit = Fabricate(:credit)
          get '/credit_transfers', VALID_HEADERS
          expect(json_body).to_not include(other_credit.eref)
        end

        it 'returns includes the existing credit' do
          get '/credit_transfers', VALID_HEADERS
          # expect(json_body).to eq('test')
          expect_json_sizes 1
        end

        describe "object format" do
          it 'exposes properly formatted data' do
            get '/credit_transfers', VALID_HEADERS
            expect_json_types '0', TRANSFER_SPEC
          end
        end

        context "when account filter is active" do
          let!(:second_account) { organization.add_account(name: 'Second account', iban: 'SECONDACCOUNT') }
          let!(:other_credit) { Fabricate(:credit, account_id: second_account.id, eref: 'other-credit') }

          it 'only returns transactions belonging to matching account' do
            get "/credit_transfers?iban=#{second_account.iban}", VALID_HEADERS
            expect_json_sizes 1
            expect_json '0', end_to_end_reference: 'other-credit'
          end

          it 'does not return transactions not belonging to matching account' do
            get "/credit_transfers?iban=#{account.iban}", VALID_HEADERS
            expect_json_sizes 1
            expect_json '0', end_to_end_reference: 'my-credit'
          end

          it 'allows to specify multiple accounts' do
            get "/credit_transfers?iban=#{account.iban},#{second_account.iban}", VALID_HEADERS
            expect_json_sizes 2
          end
        end

        describe 'pagination' do
          before { Box::Transaction.dataset.destroy }

          let!(:credit_old) { Fabricate(:credit, eref: 'credit-old', account_id: account.id) }
          let!(:credit_new) { Fabricate(:credit, eref: 'credit-new', account_id: account.id) }

          it 'returns multiple items by default' do
            get "/credit_transfers", VALID_HEADERS
            expect_json_sizes 2
          end

          it 'orders by name' do
            get "/credit_transfers", VALID_HEADERS
            expect_json '0', end_to_end_reference: 'credit-new'
            expect_json '1', end_to_end_reference: 'credit-old'
          end

          it 'allows to specify items per page' do
            get "/credit_transfers?per_page=1", VALID_HEADERS
            expect_json_sizes 1
          end

          it 'allows to specify the page' do
            get "/credit_transfers?page=1&per_page=1", VALID_HEADERS
            expect_json '0', end_to_end_reference: 'credit-new'

            get "/credit_transfers?page=2&per_page=1", VALID_HEADERS
            expect_json '0', end_to_end_reference: 'credit-old'
          end

          it 'sets pagination headers' do
            get "/credit_transfers?per_page=1", VALID_HEADERS
            expect(headers['Link']).to include("rel='next'")
          end
        end
      end
    end


    ###
    ### POST /accounts
    ###

    describe 'POST: /credit_transfers' do
      context "when no valid access token is provided" do
        it 'returns a 401' do
          post '/credit_transfers', {}, INVALID_TOKEN_HEADER
          expect_status 401
        end
      end
    end


    ###
    ### GET /accounts
    ###

    describe 'GET: /credit_transfers/:id' do
      context "when no valid access token is provided" do
        it 'returns a 401' do
          get '/credit_transfers/1', INVALID_TOKEN_HEADER
          expect_status 401
        end
      end
    end
  end
end
