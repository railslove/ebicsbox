# frozen_string_literal: true

require "spec_helper"
require_relative "../../../box/business_processes/foreign_credit"

module Box
  RSpec.describe Apis::V2::CreditTransfers do
    include_context "valid user"
    include_context "with account"

    TRANSFER_SPEC = {
      id: :string,
      account: :string,
      name: :string,
      iban: :string,
      bic: :string,
      amount_in_cents: :integer,
      currency: :string,
      end_to_end_reference: :string,
      ebics_transaction_id: :string,
      status: :string,
      reference: :string,
      executed_on: :date,
      _links: :object
    }.freeze

    ###
    ### GET /accounts
    ###

    describe "GET: /credit_transfers" do
      context "when no valid access token is provided" do
        it "returns a 401" do
          get "/credit_transfers", TestHelpers::INVALID_TOKEN_HEADER
          expect_status 401
        end
      end

      context "when no credits are available" do
        it "returns a 200" do
          get "/credit_transfers", TestHelpers::VALID_HEADERS
          expect_status 200
        end

        it "returns an empty array" do
          get "/credit_transfers", TestHelpers::VALID_HEADERS
          expect_json []
        end
      end

      context "when credits exist" do
        let!(:credit) { Fabricate(:credit, eref: "my-credit", account_id: account.id) }

        it "does not show credits from other organizations" do
          Fabricate(:organization)
          other_credit = Fabricate(:credit)
          get "/credit_transfers", TestHelpers::VALID_HEADERS
          expect(json_body).to_not include(other_credit.eref)
        end

        it "returns includes the existing credit" do
          get "/credit_transfers", TestHelpers::VALID_HEADERS
          expect_json_sizes 1
        end

        describe "object format" do
          it "exposes properly formatted data" do
            get "/credit_transfers", TestHelpers::VALID_HEADERS
            expect_json_types "0", TRANSFER_SPEC
          end
        end

        context "when account filter is active" do
          let!(:second_account) { organization.add_account(name: "Second account", iban: "SECONDACCOUNT") }
          let!(:other_credit) { Fabricate(:credit, account_id: second_account.id, eref: "other-credit") }

          it "only returns transactions belonging to matching account" do
            get "/credit_transfers?iban=#{second_account.iban}", TestHelpers::VALID_HEADERS
            expect_json_sizes 1
            expect_json "0", end_to_end_reference: "other-credit"
          end

          it "does not return transactions not belonging to matching account" do
            get "/credit_transfers?iban=#{account.iban}", TestHelpers::VALID_HEADERS
            expect_json_sizes 1
            expect_json "0", end_to_end_reference: "my-credit"
          end

          it "allows to specify multiple accounts" do
            get "/credit_transfers?iban=#{account.iban},#{second_account.iban}", TestHelpers::VALID_HEADERS
            expect_json_sizes 2
          end
        end

        context "when status filter is active" do
          let!(:other_credit) { Fabricate(:credit, account_id: account.id, eref: "another-credit", status: "failed") }

          it "only return transactions with the defined status" do
            get "/credit_transfers?status=failed", TestHelpers::VALID_HEADERS
            expect_json_sizes 1
            expect_json "0", status: "failed"
          end

          it "allows to specify multiple status" do
            get "/credit_transfers?status=failed,created,file_upload,funds_debited", TestHelpers::VALID_HEADERS
            expect_json_sizes 2
          end
        end

        describe "pagination" do
          before { Box::Transaction.dataset.destroy }

          let!(:credit_old) { Fabricate(:credit, eref: "credit-old", account_id: account.id) }
          let!(:credit_new) { Fabricate(:credit, eref: "credit-new", account_id: account.id) }

          it "returns multiple items by default" do
            get "/credit_transfers", TestHelpers::VALID_HEADERS
            expect_json_sizes 2
          end

          it "orders by name" do
            get "/credit_transfers", TestHelpers::VALID_HEADERS
            expect_json "0", end_to_end_reference: "credit-new"
            expect_json "1", end_to_end_reference: "credit-old"
          end

          it "allows to specify items per page" do
            get "/credit_transfers?per_page=1", TestHelpers::VALID_HEADERS
            expect_json_sizes 1
          end

          it "allows to specify the page" do
            get "/credit_transfers?page=1&per_page=1", TestHelpers::VALID_HEADERS
            expect_json "0", end_to_end_reference: "credit-new"

            get "/credit_transfers?page=2&per_page=1", TestHelpers::VALID_HEADERS
            expect_json "0", end_to_end_reference: "credit-old"
          end

          it "sets pagination headers" do
            get "/credit_transfers?per_page=1", TestHelpers::VALID_HEADERS
            expect(headers["Link"]).to include("rel='next'")
          end
        end
      end
    end

    ###
    ### POST /accounts
    ###

    describe "POST: /credit_transfers" do
      let!(:account) { Fabricate(:activated_account, organization_id: organization.id, name: "My test account", iban: "DE75374497411708271691", bic: "GENODEF1NDH") }
      let(:valid_attributes) do
        {
          account: account.iban,
          name: "Max Mustermann",
          iban: "DE75374497411708271691",
          bic: "GENODEF1NDH",
          amount_in_cents: 123_45,
          end_to_end_reference: "valid-credit-ref"
        }
      end

      let(:valid_attributes_foreign) do
        valid_attributes.merge(
          currency: "CHF",
          country_code: "CH",
          end_to_end_reference: "TEST"
        )
      end

      context "when no valid access token is provided" do
        it "returns a 401" do
          post "/credit_transfers", {}, TestHelpers::INVALID_TOKEN_HEADER
          expect_status 401
        end
      end

      context "invalid data" do
        it "returns a 401" do
          post "/credit_transfers", {}, TestHelpers::VALID_HEADERS
          expect_status 400
        end

        it "specifies invalid fields" do
          post "/credit_transfers", {}, TestHelpers::VALID_HEADERS
          expect_json_types errors: {
            account: :array_of_strings,
            name: :array_of_strings,
            iban: :array_of_strings,
            bic: :array_or_null,
            amount_in_cents: :array_of_strings,
            end_to_end_reference: :array_of_strings
          }
        end

        it "provides a proper error message" do
          post "/credit_transfers", {}, TestHelpers::VALID_HEADERS
          expect_json message: "Validation of your request's payload failed!"
        end

        it "does not allow two credits with the same end_to_end_reference for one account" do
          Fabricate(:credit, account_id: account.id, eref: "my-credit-eref")
          post "/credit_transfers", {account: account.iban, end_to_end_reference: "my-credit-eref"}, TestHelpers::VALID_HEADERS
          expect_json "errors.end_to_end_reference", ["must be unique"]
        end

        it "allows a max length of 140 characters for reference" do
          post "/credit_transfers", {reference: "a" * 141}, TestHelpers::VALID_HEADERS
          expect_json "errors.reference", ["must be at the most 140 characters long"]
        end

        it "fails on invalid IBAN" do
          post "/credit_transfers", valid_attributes.merge(iban: "MYTESTIBAN"), TestHelpers::VALID_HEADERS
          expect_json message: "Failed to initiate credit transfer.", errors: {base: "Iban MYTESTIBAN is invalid"}
        end

        it "fails on invalid BIC" do
          post "/credit_transfers", valid_attributes.merge(bic: "MYTESTBIC"), TestHelpers::VALID_HEADERS
          expect_json message: "Failed to initiate credit transfer.", errors: {base: "Bic MYTESTBIC is invalid"}
        end

        it "fails on too long end_to_end_reference" do
          post "/credit_transfers", valid_attributes.merge(end_to_end_reference: "E" * 65), TestHelpers::VALID_HEADERS
          expect_json "errors.end_to_end_reference", ["must be at the most 64 characters long"]
        end

        context "foreign currency" do
          it "fails on missing country_code" do
            post "/credit_transfers", valid_attributes.merge(currency: "CHF"), TestHelpers::VALID_HEADERS
            expect_json "errors.country_code", ["is missing", "is empty"]
          end

          it "fails on missing bic" do
            post "/credit_transfers", valid_attributes.merge(currency: "CHF", bic: nil), TestHelpers::VALID_HEADERS
            expect_json "errors.bic", ["is empty"]
          end

          it "fails on invalid currency" do
            post "/credit_transfers", valid_attributes.merge(currency: "CHF123"), TestHelpers::VALID_HEADERS
            expect_json "errors.currency", ["must be at the most 3 characters long"]
          end

          it "fails on too long end_to_end_reference" do
            post "/credit_transfers", valid_attributes.merge(currency: "CHF", end_to_end_reference: "E" * 28), TestHelpers::VALID_HEADERS
            expect_json "errors.end_to_end_reference", ["must be at the most 27 characters long"]
          end
        end
      end

      context "valid data" do
        it "returns a 201" do
          post "/credit_transfers", valid_attributes, TestHelpers::VALID_HEADERS
          expect_status 201
        end

        it "returns a proper message" do
          post "/credit_transfers", valid_attributes, TestHelpers::VALID_HEADERS
          expect_json "message", "Credit transfer has been initiated successfully!"
        end

        it "triggers a credit transfer" do
          expect(Credit).to receive(:create!)
          post "/credit_transfers", valid_attributes, TestHelpers::VALID_HEADERS
        end

        it "triggers a credit transfer without bic" do
          expect(Credit).to receive(:create!)
          post "/credit_transfers", valid_attributes.except(:bic), TestHelpers::VALID_HEADERS
        end

        it "transactions without bic should be valid" do
          expect(Queue).to receive(:execute_credit)
          post "/credit_transfers", valid_attributes.except(:bic), TestHelpers::VALID_HEADERS
        end

        it "transforms parameters so they are understood by credit business process" do
          expect(Credit).to receive(:create!).with(account, anything, user)
          post "/credit_transfers", valid_attributes, TestHelpers::VALID_HEADERS
        end

        it "allows same end_to_end_reference for two different accounts" do
          other_account = Fabricate(:account, organization_id: account.organization_id, iban: "DE41405327214540168131")
          Fabricate(:credit, account_id: other_account.id, eref: "my-credit-eref")
          post "/credit_transfers", valid_attributes.merge(end_to_end_reference: "my-credit-eref"), TestHelpers::VALID_HEADERS
          expect_status 201
        end

        it "ignores fee_handling & country_code flag" do
          allow(Credit).to receive(:v2_create!).and_return(true)
          post "/credit_transfers", valid_attributes.merge(fee_handling: :split, country_code: "FooBar"), TestHelpers::VALID_HEADERS

          expected_attributes = valid_attributes
            .merge(reference: nil, execution_date: Date.today, urgent: false, currency: "EUR")
            .stringify_keys

          expect(Credit).to have_received(:v2_create!).with(anything, anything, expected_attributes)
        end

        context "foreign currency" do
          before do
            allow_any_instance_of(Epics::Client).to receive(:HTD).and_return(File.read("spec/fixtures/htd.xml"))
          end

          it "returns a 201" do
            post "/credit_transfers", valid_attributes_foreign, TestHelpers::VALID_HEADERS
            expect_status 201
          end
        end

        it "ignores urgent flag" do
          allow(ForeignCredit).to receive(:v2_create!).and_return(true)
          post "/credit_transfers", valid_attributes_foreign.merge(urgent: true), TestHelpers::VALID_HEADERS

          expected_attributes = valid_attributes_foreign
            .merge(reference: nil, execution_date: Date.today, fee_handling: :split)
            .stringify_keys

          expect(ForeignCredit).to have_received(:v2_create!).with(anything, anything, expected_attributes)
        end
      end
    end

    ###
    ### GET /accounts
    ###

    describe "GET: /credit_transfers/:id" do
      context "when no valid access token is provided" do
        it "returns a 401" do
          get "/credit_transfers/1", TestHelpers::INVALID_TOKEN_HEADER
          expect_status 401
        end
      end

      context "when credit does not exist" do
        context "when invalid uuid" do
          it "returns a 404" do
            get "/credit_transfers/UNKNOWN_ID", TestHelpers::VALID_HEADERS
            expect_status 404
          end
        end

        context "when uuid does not exist" do
          it "returns a 404" do
            get "/credit_transfers/d23d5d52-28fc-4352-a094-b69818a3fdf1", TestHelpers::VALID_HEADERS
            expect_status 404
          end
        end
      end

      context "when credit does exist" do
        let!(:credit) { Fabricate(:credit, eref: "my-credit", account_id: account.id) }

        it "returns a 200" do
          id = credit.public_id
          get "/credit_transfers/#{id}", TestHelpers::VALID_HEADERS
          expect_status 200
        end

        it "exposes properly formatted data" do
          get "/credit_transfers/#{credit.public_id}", TestHelpers::VALID_HEADERS
          expect_json_types TRANSFER_SPEC
        end
      end
    end
  end
end
