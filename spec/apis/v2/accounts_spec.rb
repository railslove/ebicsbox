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

    ###
    ### GET /accounts
    ###

    describe 'GET: /accounts' do
      context "when no valid access token is provided" do
        it 'returns a 401' do
          get '/accounts', { 'Accept' => 'application/vnd.ebicsbox-v2+json', 'Authorization' => 'Bearer invalid-token' }
          expect_status 401
        end
      end

      context "when no accounts are available" do
        it 'returns a 200' do
          get '/accounts', { 'Accept' => 'application/vnd.ebicsbox-v2+json', 'Authorization' => 'Bearer test-token' }
          expect_status 200
        end

        it 'returns an empty array' do
          get '/accounts', { 'Accept' => 'application/vnd.ebicsbox-v2+json', 'Authorization' => 'Bearer test-token' }
          expect_json []
        end
      end

      context "when accounts are available" do
        let!(:account) { Fabricate(:activated_account, organization_id: organization.id) }

        it 'returns includes the existing account' do
          get '/accounts', { 'Accept' => 'application/vnd.ebicsbox-v2+json', 'Authorization' => 'Bearer test-token' }
          expect_json_sizes 1
        end

        describe "object format" do
          it 'exposes properly formatted data' do
            get '/accounts', { 'Accept' => 'application/vnd.ebicsbox-v2+json', 'Authorization' => 'Bearer test-token' }
            expect_json_types '0', ACCOUNT_SPEC
          end
        end

        describe 'filtering by status' do
          before { Box::Account.dataset.destroy }

          let!(:not_activated_account) { Fabricate(:account, name: 'not-activated', organization_id: organization.id) }
          let!(:activated_account) { Fabricate(:activated_account, name: 'activated', organization_id: organization.id) }

          it 'returns all accounts by default' do
            get "/accounts", { 'Accept' => 'application/vnd.ebicsbox-v2+json', 'Authorization' => 'Bearer test-token' }
            expect_json_sizes 2
          end

          it 'returns only activated accounts when requested' do
            get "/accounts?status=activated", { 'Accept' => 'application/vnd.ebicsbox-v2+json', 'Authorization' => 'Bearer test-token' }
            expect_json_sizes 1
            expect_json '0', name: 'activated'
          end

          it 'returns only not_activated accounts when requested' do
            get "/accounts?status=not_activated", { 'Accept' => 'application/vnd.ebicsbox-v2+json', 'Authorization' => 'Bearer test-token' }
            expect_json_sizes 1
            expect_json '0', name: 'not-activated'
          end
        end

        describe 'pagination' do
          before { Box::Account.dataset.destroy }

          let!(:account1) { Fabricate(:account, name: "z account", organization_id: organization.id) }
          let!(:account2) { Fabricate(:account, name: "a account", organization_id: organization.id) }

          it 'returns multiple items by default' do
            get "/accounts", { 'Accept' => 'application/vnd.ebicsbox-v2+json', 'Authorization' => 'Bearer test-token' }
            expect_json_sizes 2
          end

          it 'orders by name' do
            get "/accounts", { 'Accept' => 'application/vnd.ebicsbox-v2+json', 'Authorization' => 'Bearer test-token' }
            expect_json '0', name: 'a account'
            expect_json '1', name: 'z account'
          end

          it 'allows to specify items per page' do
            get "/accounts?per_page=1", { 'Accept' => 'application/vnd.ebicsbox-v2+json', 'Authorization' => 'Bearer test-token' }
            expect_json_sizes 1
          end

          it 'allows to specify the page' do
            get "/accounts?page=1&per_page=1", { 'Accept' => 'application/vnd.ebicsbox-v2+json', 'Authorization' => 'Bearer test-token' }
            expect_json '0', name: 'a account'

            get "/accounts?page=2&per_page=1", { 'Accept' => 'application/vnd.ebicsbox-v2+json', 'Authorization' => 'Bearer test-token' }
            expect_json '0', name: 'z account'
          end

          it 'sets pagination headers' do
            get "/accounts?per_page=1", { 'Accept' => 'application/vnd.ebicsbox-v2+json', 'Authorization' => 'Bearer test-token' }
            expect(headers['Link']).to include("rel='next'")
          end
        end
      end
    end

    ###
    ### POST /accounts
    ###

    describe 'POST: /accounts' do

    end

    ###
    ### GET /accounts/:iban
    ###

    describe 'GET: /accounts/:iban' do
      let!(:account) { Fabricate(:activated_account, organization_id: organization.id) }

      context "when no valid access token is provided" do
        it 'returns a 401' do
          get "/accounts/#{account.iban}", { 'Accept' => 'application/vnd.ebicsbox-v2+json', 'Authorization' => 'Bearer invalid-token' }
          expect_status 401
        end
      end

      context "when account does not exist" do
        it 'returns a 404' do
          get "/accounts/UNKNOWN_IBAN", { 'Accept' => 'application/vnd.ebicsbox-v2+json', 'Authorization' => 'Bearer test-token' }
          expect_status 404
        end
      end

      context "when account does exist" do
        it 'returns a 200' do
          get "/accounts/#{account.iban}", { 'Accept' => 'application/vnd.ebicsbox-v2+json', 'Authorization' => 'Bearer test-token' }
          expect_status 200
        end

        it 'exposes properly formatted data' do
          get "/accounts/#{account.iban}", { 'Accept' => 'application/vnd.ebicsbox-v2+json', 'Authorization' => 'Bearer test-token' }
          expect_json_types ACCOUNT_SPEC
        end
      end
    end

  end
end
