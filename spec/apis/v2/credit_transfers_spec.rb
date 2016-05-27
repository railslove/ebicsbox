require 'spec_helper'

module Box
  RSpec.describe Apis::V2::CreditTransfers do
    include_context 'valid user'
    include_context 'with account'

    TRANSFER_SPEC = {
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
      _links: :object,
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
      let!(:account) { Fabricate(:activated_account, organization_id: organization.id, name: 'My test account', iban: 'DE75374497411708271691', bic: 'GENODEF1NDH') }
      let(:valid_attributes) do
        {
          account: account.iban,
          name: "Max Mustermann",
          iban: "DE75374497411708271691",
          bic: "GENODEF1NDH",
          amount_in_cents: 123_45,
          end_to_end_reference: "valid-credit-ref",
        }
      end

      context "when no valid access token is provided" do
        it 'returns a 401' do
          post '/credit_transfers', {}, INVALID_TOKEN_HEADER
          expect_status 401
        end
      end

      context 'invalid data' do
        it 'returns a 401' do
          post "/credit_transfers", {}, VALID_HEADERS
          expect_status 400
        end

        it 'specifies invalid fields' do
          post "/credit_transfers", {}, VALID_HEADERS
          expect_json_types errors: {
            account: :array_of_strings,
            name: :array_of_strings,
            iban: :array_of_strings,
            bic: :array_of_strings,
            amount_in_cents: :array_of_strings,
            end_to_end_reference: :array_of_strings,
          }
        end

        it 'provides a proper error message' do
          post "/credit_transfers", {}, VALID_HEADERS
          expect_json message: "Validation of your request's payload failed!"
        end

        it 'does not allow two credits with the same end_to_end_reference for one account' do
          credit = Fabricate(:credit, account_id: account.id, eref: 'my-credit-eref')
          post "/credit_transfers", { account: account.iban, end_to_end_reference: 'my-credit-eref' }, VALID_HEADERS
          expect_json 'errors.end_to_end_reference', ["must be unique"]
        end

        it 'allows a max length of 140 characters for reference' do
          post "/credit_transfers", { reference: 'a' * 141 }, VALID_HEADERS
          expect_json 'errors.reference', ["must be at the most 140 characters long"]
        end

        it 'fails on invalid IBAN' do
          post "/credit_transfers", valid_attributes.merge(iban: 'MYTESTIBAN'), VALID_HEADERS
          expect_json message: "Failed to initiate credit transfer.", errors: { base: "Iban is invalid" }
        end

        it 'fails on invalid BIC' do
          post "/credit_transfers", valid_attributes.merge(bic: 'MYTESTBIC'), VALID_HEADERS
          expect_json message: "Failed to initiate credit transfer.", errors: { base: "Bic is invalid" }
        end
      end

      context 'valid data' do
        it 'returns a 201' do
          post "/credit_transfers", valid_attributes, VALID_HEADERS
          expect_status 201
        end

        it 'returns a proper message' do
          post "/credit_transfers", valid_attributes, VALID_HEADERS
          expect_json 'message', 'Credit transfer has been initiated successfully!'
        end

        it 'triggers a credit transfer' do
          expect(Credit).to receive(:create!)
          post "/credit_transfers", valid_attributes, VALID_HEADERS
        end

        it 'transforms parameters so they are understood by credit business process' do
          expect(Credit).to receive(:create!).with(account, anything, user)
          post "/credit_transfers", valid_attributes, VALID_HEADERS
        end

        it 'allows same end_to_end_reference for two different accounts' do
          other_account = Fabricate(:account, organization_id: account.organization_id)
          credit = Fabricate(:credit, account_id: other_account.id, eref: 'my-credit-eref')
          post "/credit_transfers", valid_attributes.merge(end_to_end_reference: 'my-credit-eref'), VALID_HEADERS
          expect_status 201
        end

        context "when sandbox server mode" do
          before { allow(Box.configuration).to receive(:sandbox?).and_return(true) }

          it 'executes order immediately'
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

      context "when credit does not exist" do
        context "when invalid uuid" do
          it 'returns a 404' do
            get "/credit_transfers/UNKNOWN_ID", VALID_HEADERS
            expect_status 404
          end
        end

        context "when uuid does not exist" do
          it 'returns a 404' do
            get "/credit_transfers/d23d5d52-28fc-4352-a094-b69818a3fdf1", VALID_HEADERS
            expect_status 404
          end
        end
      end

      context "when credit does exist" do
        let!(:credit) { Fabricate(:credit, eref: 'my-credit', account_id: account.id) }

        it 'returns a 200' do
          id = credit.public_id
          get "/credit_transfers/#{id}", VALID_HEADERS
          expect_status 200
        end

        it 'exposes properly formatted data' do
          get "/credit_transfers/#{credit.public_id}", VALID_HEADERS
          expect_json_types TRANSFER_SPEC
        end
      end

    end
  end
end
