# frozen_string_literal: true

require "active_support/all"
require "cmxl"

require_relative "../../box/models/account"
require_relative "../../box/business_processes/import_bank_statement"

module Box
  module BusinessProcesses
    RSpec.describe ImportBankStatement do
      let(:account) { Account.create(host: "HOST", iban: "iban1234567") }
      let(:mt940_fixture) { "single_valid.mt940" }
      let(:mt940) { File.read("spec/fixtures/#{mt940_fixture}") }
      let(:camt_account) { Account.create(host: "HOST", iban: "iban1234567", statements_format: "camt53") }
      let(:camt_fixture) { "camt_statement.xml" }
      let(:camt) { File.read("spec/fixtures/#{camt_fixture}") }

      describe ".from_mt940" do
        it "calls process with parsed data" do
          expect(described_class).to receive(:process).with(an_instance_of(Cmxl::Statement), account)
          described_class.from_mt940(mt940, account)
        end
      end

      describe ".process" do
        let(:cmxl) { Cmxl.parse(mt940).first }

        def import(cmxl, account)
          described_class.process(cmxl, account)
        end

        describe "input validation" do
          context "invalid raw bank statement" do
            it "fails with an error" do
              expect { described_class.process(nil, account) }.to raise_error(ImportBankStatement::InvalidInput)
            end
          end

          context "data for unknown sub-account" do
            let(:mt940_fixture) { "single_subaccount.mt940" }

            it "fails with an error" do
              expect { import(cmxl, account) }.to raise_error(ImportBankStatement::InvalidInput)
            end
          end
        end

        describe "database record creation" do
          describe "bank statement already exists" do
            let!(:bank_statement) { BankStatement.create(sha: described_class.checksum(cmxl, account)) }

            it "does not create a new bank statement" do
              expect { import(cmxl, account) }.to_not(change(BankStatement, :count))
            end

            it "returns the existing bank statement" do
              expect(import(cmxl, account)).to eq(bank_statement)
            end
          end

          describe "year over year duplicated statement numbers" do
            let!(:cmxl_2016) { Cmxl.parse(File.read("spec/fixtures/duplicated_sequence_number_2016.mt940")).first }
            let!(:cmxl_2017) { Cmxl.parse(File.read("spec/fixtures/duplicated_sequence_number_2017.mt940")).first }

            it "does create two bank statements" do
              expect { import(cmxl_2016, account) }.to(change(BankStatement, :count).to(1))
              expect { import(cmxl_2017, account) }.to(change(BankStatement, :count).to(2))
            end

            it "recognizes duplicated statements per year" do
              expect { import(cmxl_2017, account) }.to(change(BankStatement, :count).to(1))
              expect { import(cmxl_2017, account) }.not_to(change(BankStatement, :count))
            end
          end

          describe "bank statement does not yet exist" do
            it "creates a new bank statement" do
              expect { import(cmxl, account) }.to(change(BankStatement, :count).by(1))
            end

            it "returns a bank statement record" do
              expect(import(cmxl, account)).to be_an_instance_of(BankStatement)
            end
          end

          describe "camt statements" do
            it "creates a new bank statement from camt" do
              c53 = SepaFileParser::String.parse(camt).statements.first
              expect { import(c53, camt_account) }.to(change(BankStatement, :count).by(1))
            end

            it "extracts a date for bank statements" do
              c53 = SepaFileParser::String.parse(camt).statements.first
              expect(import(c53, camt_account).year).to eq(2013)
            end
          end
        end

        describe "account balance updates" do
          context "no old balance is set" do
            before { account.set_balance(nil, nil) }

            it "stores new closing balance date" do
              expect { import(cmxl, account) }.to(change { account.reload.balance_date })
            end

            it "stores new closing balance" do
              expect { import(cmxl, account) }.to(change { account.reload.balance_in_cents })
            end
          end

          context "an old statement is added" do
            let(:mt940_fixture) { "single_valid_2016-03-15.mt940" }

            before { account.set_balance(Date.new(2016, 0o3, 20), 1_000_00) }

            it "does not change closing balance date" do
              expect { import(cmxl, account) }.to_not(change { account.reload.balance_date })
            end

            it "does not change closing balance date" do
              expect { import(cmxl, account) }.to_not(change { account.reload.balance_in_cents })
            end
          end

          context "a new bank statement is imported" do
            let(:mt940_fixture) { "single_valid_2016-03-15.mt940" }

            before { account.set_balance(Date.new(2016, 0o3, 10), 1_000_00) }

            it "stores new closing balance date" do
              expect { import(cmxl, account) }.to(change { account.reload.balance_date })
            end

            it "stores new closing balance" do
              expect { import(cmxl, account) }.to(change { account.reload.balance_in_cents })
            end
          end
        end
      end
    end
  end
end
