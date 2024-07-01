# frozen_string_literal: true

require "spec_helper"

module Box
  RSpec.describe Apis::V2::Transactions do
    include_context "valid user"

    TRANSACTION_SPEC = {
      id: :string,
      account: :string,
      name: :string,
      iban: :string,
      bic: :string,
      amount_in_cents: :integer,
      executed_on: :date,
      type: :string,
      reference: :string,
      end_to_end_reference: :string,
      settled_at: :string
    }.freeze

    describe "GET: /transactions" do
      context "when no valid access token is provided" do
        it "returns a 404" do
          get "/transactions", TestHelpers::INVALID_TOKEN_HEADER
          expect_status 401
        end
      end

      context "when no transactions are available" do
        it "returns a 200" do
          get "/transactions", TestHelpers::VALID_HEADERS
          expect_status 200
        end

        it "returns an empty array" do
          get "/transactions", TestHelpers::VALID_HEADERS
          expect_json []
        end
      end

      context "when transactions are available" do
        include_context "with account"

        let!(:trx1) { account.add_statement(Fabricate.attributes_for(:statement, eref: "trx-1")) }

        it "returns a 200" do
          get "/transactions", TestHelpers::VALID_HEADERS
          expect_status 200
        end

        it "returns an array of those transactions" do
          get "/transactions", TestHelpers::VALID_HEADERS
          expect_json "?", end_to_end_reference: "trx-1"
        end

        it "does not include transactions from accounts belonging to a different organization" do
          other_orga = Fabricate(:organization)
          account = other_orga.add_account(organization_id: 2, iban: "OTHERIBAN")
          account.add_statement(eref: "trx-2")

          get "/transactions", TestHelpers::VALID_HEADERS
          expect_json_sizes 1
        end

        it "formats the response decument properly" do
          get "/transactions", TestHelpers::VALID_HEADERS
          expect_json_types "0", TRANSACTION_SPEC
        end
      end

      describe "pagination" do
        include_context "with account"

        let!(:trx1) { account.add_statement(eref: "trx-1", date: "2016-01-01") }
        let!(:trx2) { account.add_statement(eref: "trx-2", date: "2016-01-02") }

        it "returns multiple items by default" do
          get "/transactions", TestHelpers::VALID_HEADERS
          expect_json_sizes 2
        end

        it "orders by decending date" do
          get "/transactions", TestHelpers::VALID_HEADERS
          expect_json "0", end_to_end_reference: "trx-2"
          expect_json "1", end_to_end_reference: "trx-1"
        end

        it "allows to specify items per page" do
          get "/transactions?per_page=1", TestHelpers::VALID_HEADERS
          expect_json_sizes 1
        end

        it "allows to specify the page" do
          get "/transactions?page=1&per_page=1", TestHelpers::VALID_HEADERS
          expect_json "*", end_to_end_reference: "trx-2"

          get "/transactions?page=2&per_page=1", TestHelpers::VALID_HEADERS
          expect_json "*", end_to_end_reference: "trx-1"
        end

        it "sets pagination headers" do
          get "/transactions?per_page=1", TestHelpers::VALID_HEADERS
          expect(headers["Link"]).to include("rel='next'")
        end
      end

      context "when account filter is active" do
        include_context "with account"

        let!(:second_account) { organization.add_account(name: "Second account", iban: "SECONDACCOUNT") }
        let!(:first_transaction) { account.add_statement(eref: "first-trx") }
        let!(:other_transaction) { second_account.add_statement(eref: "other-trx") }

        it "only returns transactions belonging to matching account" do
          get "/transactions?iban=#{second_account.iban}", TestHelpers::VALID_HEADERS
          expect_json_sizes 1
          expect_json "0", end_to_end_reference: "other-trx"
        end

        it "does not return transactions not belonging to matching account" do
          get "/transactions?iban=#{account.iban}", TestHelpers::VALID_HEADERS
          expect_json_sizes 1
          expect_json "0", end_to_end_reference: "first-trx"
        end

        it "allows to specify multiple accounts" do
          get "/transactions?iban=#{account.iban},#{second_account.iban}", TestHelpers::VALID_HEADERS
          expect_json_sizes 2
        end
      end

      context "when end_to_end_reference filter is active" do
        include_context "with account"

        let!(:first_transaction) { account.add_statement(eref: "REF001") }
        let!(:second_transaction) { account.add_statement(eref: "REF001") }
        let!(:third_transaction) { account.add_statement(eref: "REF002") }

        it "only returns transactions with matching eref" do
          get "/transactions?end_to_end_reference=REF001", TestHelpers::VALID_HEADERS
          expect_json_sizes 2
          expect_json "0", end_to_end_reference: "REF001"
          expect_json "1", end_to_end_reference: "REF001"
        end
      end

      context "when date filter is active" do
        include_context "with account"

        let!(:old) { account.add_statement(eref: "trx-1", date: "2016-01-01") }
        let!(:new) { account.add_statement(eref: "trx-2", date: "2016-02-01") }

        it "allows to filter only by lower boundary date" do
          get "/transactions?from=2016-02-01", TestHelpers::VALID_HEADERS
          expect_json "*", end_to_end_reference: "trx-2"
        end

        it "allows to filter only by upper boundary date" do
          get "/transactions?to=2016-01-31", TestHelpers::VALID_HEADERS
          expect_json "*", end_to_end_reference: "trx-1"
        end

        it "allows to filter by upper and lower boundary date" do
          get "/transactions?from=2016-01-30&to=2016-01-31", TestHelpers::VALID_HEADERS
          expect_json_sizes 0
        end
      end

      context "when type filter is active" do
        include_context "with account"

        let!(:debit) { account.add_statement(eref: "trx-1", debit: true) }
        let!(:credit) { account.add_statement(eref: "trx-2", debit: false) }

        it "only returns transactions which match its type" do
          get "/transactions?type=debit", TestHelpers::VALID_HEADERS
          expect_json "*", type: "debit"
        end
      end
    end

    describe "GET /trasactions/:id" do
      # organization and user are defined in the valid_user context
      let!(:org_account) { Fabricate(:account, organization: organization) }

      let!(:other_org_user) { Fabricate(:user, access_token: "foobar") }
      let!(:other_org) { Fabricate(:organization) }
      let!(:other_org_account) { Fabricate(:account, organization: other_org) }

      subject(:trx) { Fabricate(:statement, account: org_account) }

      it "returns 404 if transaction by id does not exist" do
        trx.destroy

        get "/transactions/#{trx.public_id}", TestHelpers::VALID_HEADERS
        expect_status 404
      end

      it "returns 404 if transaction does not belong to current organization" do
        get "/transactions/#{trx.public_id}", TestHelpers::VALID_HEADERS.merge("Authorization" => "Bearer foobar")
        expect_status 404
      end

      it "returns 200 if transaction found" do
        get "/transactions/#{trx.public_id}", TestHelpers::VALID_HEADERS
        expect_status 200
      end

      it "returns transaction" do
        get "/transactions/#{trx.public_id}", TestHelpers::VALID_HEADERS
        expect(response.body).to eql(Box::Entities::V2::Transaction.new(trx).to_json)
      end
    end
  end
end
