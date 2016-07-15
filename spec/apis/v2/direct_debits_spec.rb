require 'spec_helper'

    

module Box
  RSpec.describe Apis::V2::DirectDebits do
    include_context 'valid user'
    include_context 'with account'

    let!(:transfer_spec) do
      {
        id: :string,
        account: :string,
        name: :string,
        iban: :string,
        bic: :string,
        amount_in_cents: :integer,
        end_to_end_reference: :string,
        status: :string,
        reference: :string,
        executed_on: :date,
        links: :object
      }
    end

    let!(:valid_headers) do 
      {
        'Accept' => 'application/vnd.ebicsbox-v2+json',
        'Authorization' => 'Bearer test-token'
      }
    end

    let!(:invalid_token_header) do
      {
        'Accept' => 'application/vnd.ebicsbox-v2+json',
        'Authorization' => 'Bearer invalid-token'
      }
    end

    ###
    ### GET /direct_debits
    ###

    describe 'GET: /direct_debits' do
      context "when no valid access token is provided" do
        it 'returns a 401' do
          get '/direct_debits', invalid_token_header
          expect_status 401
        end
      end

      context "when no debits are available" do
        it 'returns a 200' do
          get '/direct_debits', valid_headers
          expect_status 200
        end
      
        it 'returns an empty array' do
          get '/direct_debits', valid_headers
          expect_json []
        end
      end

      context 'when debits exist' do
        let!(:debit) { Fabricate(:debit, eref: 'my-debit', account_id: account.id) }

        it 'does not show debits from other organizations' do
          other_organization = Fabricate(:organization)
          other_debit = Fabricate(:debit)
          get '/direct_debits', valid_headers
          expect(json_body).to_not include(other_debit.eref)
        end
      
        it 'returns includes the existing debit' do
          get '/direct_debits', valid_headers
          expect_json_sizes 1
        end

        # describe "object format" do
        #   it 'exposes properly formatted data' do
        #     get '/direct_debits', valid_headers
        #     expect_json_types '0', transfer_spec
        #   end
        # end

        context "when account filter is active" do
          let!(:second_account) { organization.add_account(name: 'Second account', iban: 'SECONDACCOUNT') }
          let!(:other_debit) { Fabricate(:debit, account_id: second_account.id, eref: 'other-debit') }

          # it 'only returns transactions belonging to matching account' do
          #   get "/direct_debits?iban=#{second_account.iban}", valid_headers
          #   expect_json_sizes 1
          #   expect_json '0', end_to_end_reference: 'other-debit'
          # end
        end
      end
    end
  end
end
