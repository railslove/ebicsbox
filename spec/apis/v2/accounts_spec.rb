require 'spec_helper'

module Box
  RSpec.describe Apis::V2::Accounts do
    include_context 'valid user'

    ACCOUNT_SPEC = {
      name: :string,
      iban: :string,
      bic: :string,
      balance_date: :date,
      balance_in_cents: :integer,
      creditor_identifier: :string,
      callback_url: :string,
      status: :string,
      subscriber: :string,
    }

    NEW_ACCOUNT_SPEC = {
      name: :string,
      iban: :string,
      bic: :string,
      status: :string,
      subscriber: :string,
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

    describe 'GET: /accounts' do
      context "when no valid access token is provided" do
        it 'returns a 401' do
          get '/accounts', INVALID_TOKEN_HEADER
          expect_status 401
        end
      end

      context "when no accounts are available" do
        it 'returns a 200' do
          get '/accounts', VALID_HEADERS
          expect_status 200
        end

        it 'returns an empty array' do
          get '/accounts', VALID_HEADERS
          expect_json []
        end
      end

      context "when accounts are available" do
        let!(:account) { Fabricate(:activated_account, organization_id: organization.id) }

        it 'returns includes the existing account' do
          get '/accounts', VALID_HEADERS
          expect_json_sizes 1
        end

        describe "object format" do
          it 'exposes properly formatted data' do
            get '/accounts', VALID_HEADERS
            expect_json_types '0', ACCOUNT_SPEC
          end
        end

        describe 'filtering by status' do
          before { Box::Account.dataset.destroy }

          let!(:not_activated_account) { Fabricate(:account, name: 'not-activated', organization_id: organization.id) }
          let!(:activated_account) { Fabricate(:activated_account, name: 'activated', organization_id: organization.id) }

          it 'returns all accounts by default' do
            get "/accounts", VALID_HEADERS
            expect_json_sizes 2
          end

          it 'returns only activated accounts when requested' do
            get "/accounts?status=activated", VALID_HEADERS
            expect_json_sizes 1
            expect_json '0', name: 'activated'
          end

          it 'returns only not_activated accounts when requested' do
            get "/accounts?status=not_activated", VALID_HEADERS
            expect_json_sizes 1
            expect_json '0', name: 'not-activated'
          end
        end

        describe 'pagination' do
          before { Box::Account.dataset.destroy }

          let!(:account1) { Fabricate(:account, name: "z account", organization_id: organization.id) }
          let!(:account2) { Fabricate(:account, name: "a account", organization_id: organization.id) }

          it 'returns multiple items by default' do
            get "/accounts", VALID_HEADERS
            expect_json_sizes 2
          end

          it 'orders by name' do
            get "/accounts", VALID_HEADERS
            expect_json '0', name: 'a account'
            expect_json '1', name: 'z account'
          end

          it 'allows to specify items per page' do
            get "/accounts?per_page=1", VALID_HEADERS
            expect_json_sizes 1
          end

          it 'allows to specify the page' do
            get "/accounts?page=1&per_page=1", VALID_HEADERS
            expect_json '0', name: 'a account'

            get "/accounts?page=2&per_page=1", VALID_HEADERS
            expect_json '0', name: 'z account'
          end

          it 'sets pagination headers' do
            get "/accounts?per_page=1", VALID_HEADERS
            expect(headers['Link']).to include("rel='next'")
          end
        end
      end
    end

    ###
    ### POST /accounts
    ###

    describe 'POST: /accounts' do
      context "when no valid access token is provided" do
        it 'returns a 401' do
          post "/accounts", {}, INVALID_TOKEN_HEADER
          expect_status 401
        end
      end

      context 'invalid data' do
        it 'returns a 401' do
          post "/accounts", {}, VALID_HEADERS
          expect_status 400
        end

        it 'specifies invalid fields' do
          post "/accounts", {}, VALID_HEADERS
          expect_json_types errors: {
            name: :array_of_strings,
            iban: :array_of_strings,
            bic: :array_of_strings,
            host: :array_of_strings,
            partner: :array_of_strings,
            url: :array_of_strings,
            subscriber: :array_of_strings,
          }
        end

        it 'provides a proper error message' do
          post "/accounts", {}, VALID_HEADERS
          expect_json message: "Validation of your request's payload failed!"
        end

        it 'does not allow two accounts with the same IBAN' do
          account = Fabricate(:account, organization_id: organization.id)
          payload = Fabricate.attributes_for(:account)
          post "/accounts", payload.merge(subscriber: "SOMEUSER", iban: account.iban), VALID_HEADERS
          expect_json 'errors.iban', ["must be unique"]
        end

        it 'handles bank related errors when setting up an account' do
          allow_any_instance_of(Subscriber).to receive(:setup!).and_return(false)
          payload = Fabricate.attributes_for(:account)
          post "/accounts", payload.merge(subscriber: "SOMEUSER"), VALID_HEADERS
          expect_json 'message', 'Failed to setup subscriber with your bank. Make sure your data is valid and retry!'
        end
      end

      context 'valid data' do
        before { allow_any_instance_of(Subscriber).to receive(:setup!).and_return(true) }

        def do_request
          payload = Fabricate.attributes_for(:account)
          post "/accounts", payload.merge(subscriber: "SOMEUSER"), VALID_HEADERS
        end

        it 'returns a 201' do
          do_request
          expect_status 201
        end

        it 'returns a proper message' do
          do_request
          expect_json 'message', 'Account created successfully.'
        end

        it 'returns the newly created account' do
          do_request
          expect_json_types 'account', NEW_ACCOUNT_SPEC
        end

        it 'creates a new account' do
          expect { do_request }.to change { Account.count }.by(1)
        end

        it 'creates a new subscriber' do
          expect { do_request }.to change { Subscriber.count }.by(1)
        end

        it 'triggers an event' do
          expect { do_request }.to change { Event.where(type: 'account_created').count }.by(1)
        end

        it 'allows two accounts with the same IBAN if in different organizations' do
          other_organization = Fabricate(:organization)
          account = Fabricate(:account, organization_id: other_organization.id)
          payload = Fabricate.attributes_for(:account)
          post "/accounts", payload.merge(subscriber: "SOMEUSER", iban: account.iban), VALID_HEADERS
          expect_status 201
        end

        context "when regular server mode" do
          before { allow(Box.configuration).to receive(:sandbox?).and_return(false) }

          it 'does not set fake mode' do
            do_request
            expect(Account.last.mode).to be_nil
          end

          it 'does not set a custom activation interval' do
            do_request
            expect(Account.last.config.activation_check_interval).to eq(Box.configuration.activation_check_interval)
          end
        end

        context "when sandbox server mode" do
          before { allow(Box.configuration).to receive(:sandbox?).and_return(true) }

          it 'sets fake mode' do
            do_request
            expect(Account.last.mode).to eq('Fake')
          end

          it 'sets custom activation interval to 3 seconds' do
            do_request
            expect(Account.last.config.activation_check_interval).to eq(3)
          end
        end
      end
    end

    ###
    ### GET /accounts/:iban
    ###

    describe 'GET: /accounts/:iban' do
      let!(:account) { Fabricate(:activated_account, organization_id: organization.id) }

      context "when no valid access token is provided" do
        it 'returns a 401' do
          get "/accounts/#{account.iban}", INVALID_TOKEN_HEADER
          expect_status 401
        end
      end

      context "when account does not exist" do
        it 'returns a 404' do
          get "/accounts/UNKNOWN_IBAN", VALID_HEADERS
          expect_status 404
        end
      end

      context "when account does exist" do
        it 'returns a 200' do
          get "/accounts/#{account.iban}", VALID_HEADERS
          expect_status 200
        end

        it 'exposes properly formatted data' do
          get "/accounts/#{account.iban}", VALID_HEADERS
          expect_json_types ACCOUNT_SPEC
        end
      end
    end


    ###
    ### GET /accounts/:iban/ini_letter
    ###

    describe 'GET: /accounts/:iban/ini_letter' do
      let!(:account) { Fabricate(:activated_account, organization_id: organization.id) }

      context "when no valid access token is provided" do
        it 'returns a 401' do
          get "/accounts/#{account.iban}/ini_letter", INVALID_TOKEN_HEADER
          expect_status 401
        end
      end

      context "when account does not exist" do
        it 'returns a 404' do
          get "/accounts/UNKNOWN_IBAN/ini_letter", VALID_HEADERS
          expect_status 404
        end
      end

      context 'setup has not been performed' do
        before { account.subscribers.first.update(activated_at: nil, user_id: user.id) }

        it 'fails with an error status' do
          get "/accounts/#{account.iban}/ini_letter", VALID_HEADERS
          expect_status 412
        end

        it 'fails with a meaningful error message' do
          get "/accounts/#{account.iban}/ini_letter", VALID_HEADERS
          expect_json 'message', 'Subscriber setup not yet initiated'
        end
      end

      context 'setup has been initiated before' do
        before { account.subscribers.first.update(ini_letter: "INI LETTER", user_id: user.id) }

        it 'returns a success code' do
          get "/accounts/#{account.iban}/ini_letter", VALID_HEADERS
          expect_status 200
        end

        it 'returns data as html content' do
          get "/accounts/#{account.iban}/ini_letter", VALID_HEADERS
          expect(response.headers["Content-Type"]).to eq('text/html')
        end

        it 'returns the ini letter' do
          get "/accounts/#{account.iban}/ini_letter", VALID_HEADERS
          expect(response.body).to eq("INI LETTER")
        end
      end
    end


    ###
    ### PUT /accounts/:iban
    ###

    describe 'PUT: /accounts/:iban' do
      let!(:account) { Fabricate(:activated_account, organization_id: organization.id) }

      context "when no valid access token is provided" do
        it 'returns a 401' do
          put "/accounts/#{account.iban}", { name: 'Internal Account' }, INVALID_TOKEN_HEADER
          expect_status 401
        end
      end

      context "when account does not exist" do
        it 'returns a 404' do
          put "/accounts/UNKNOWN_IBAN", { name: 'Internal Account' }, VALID_HEADERS
          expect_status 404
        end
      end

      context "when account belongs to another organization" do
        let!(:other_organization) { Fabricate(:organization) }
        let!(:other_account) { other_organization.add_account(Fabricate.attributes_for(:account, iban: 'DE41405327214540168131')) }

        it 'returns a 404' do
          put "/accounts/#{other_account.iban}", { name: 'Internal Account' }, VALID_HEADERS
          expect_status 404
        end
      end

      context 'activated account' do
        it 'cannot change iban' do
          expect {
            put "/accounts/#{account.iban}", { iban: 'new-iban' }, VALID_HEADERS
          }.to_not change { account.reload.iban }
        end

        it 'cannot change bic' do
          expect {
            put "/accounts/#{account.iban}", { bic: 'new-bic' }, VALID_HEADERS
          }.to_not change { account.reload.bic }
        end

        it 'cannot change subscriber'

        it 'allows changes of internal descriptor' do
          expect {
            put "/accounts/#{account.iban}", { descriptor: 'FooBar'}, VALID_HEADERS
          }.to change { account.reload.descriptor }.to('FooBar')
        end

        it 'allows changes of name' do
          expect {
            put "/accounts/#{account.iban}", { name: 'new-name' }, VALID_HEADERS
          }.to change { account.reload.name }
        end

        it 'allows changes of callback url' do
          expect {
            put "/accounts/#{account.iban}", { callback_url: 'new-callback-url' }, VALID_HEADERS
          }.to change { account.reload.callback_url }
        end

        it 'allows changes of creditor identifier' do
          expect {
            put "/accounts/#{account.iban}", { creditor_identifier: 'new-creditor-identifier' }, VALID_HEADERS
          }.to change { account.reload.creditor_identifier }
        end
      end
    end
  end
end
