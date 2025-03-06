# frozen_string_literal: true

require "active_support/all"
require "cmxl"

require_relative "../../box/models/account"
require_relative "../../box/models/organization"
require_relative "../../box/business_processes/import_bank_statement"
require_relative "../../box/business_processes/import_statements"

module Box
  module BusinessProcesses
    RSpec.describe ImportStatements do
      let(:organization) { Fabricate(:organization) }
      let(:account) { organization.add_account(host: "HOST", iban: "iban1234567") }
      let(:camt_account) { organization.add_account(host: "HOST", iban: "iban1234567", statements_format: "camt53") }
      let(:camt) { File.read("spec/fixtures/camt_statement") }
      let(:mt940) { File.read("spec/fixtures/single_valid.mt940") }

      before(:each) { Sidekiq::Queue.all.each(&:clear) }

      it "creates db statements for each bank statement transaction" do
        bank_statement = ImportBankStatement.from_mt940(mt940, account)
        expect(described_class).to receive(:create_statement).twice
        described_class.from_bank_statement(bank_statement)
      end

      context "statement is new" do
        it "extracts subdata from sepa subtree" do
          mt940_bank_statement = Fabricate(:mt940_statement)
          described_class.from_bank_statement(mt940_bank_statement, true)

          expect(Statement.last.values).to match(
            hash_including(
              eref: "00002266010540060117153121",
              mref: "054874",
              svwz: "GRUNSGLOB//SPARKASSE/DE 06-01-2017T15:31:21  FOLGENR. 09  VERFALLD. 1220  FREMDENTGELT 4,00 EUR",
              creditor_identifier: "DE1231231232501"
            )
          )
        end

        it "creates an event" do
          expect(Event).to receive(:publish).with(:statement_created, anything)
          mt940_bank_statement = Fabricate(:mt940_statement)
          described_class.from_bank_statement(mt940_bank_statement)
        end
      end

      context "when the statement was already imported" do
        it "does not create a new record" do
          # This is a precalculated SHA based on our algorithm

          mt940_bank_statement = Fabricate(:mt940_statement)
          Statement.create(
            sha: "a7f3bb583423771042fd4ca70c5b10cb11afa9692387253f341cc83852962066",
            account_id: mt940_bank_statement.account.id,
          )

          expect { described_class.from_bank_statement(mt940_bank_statement) }.to_not change(Statement, :count)
        end
      end

      describe "settled" do
        context "when the final import is triggered" do
          it "marks the statement as settled when the statement is already present" do
            mt940_bank_statement = Fabricate(:mt940_statement)
            Statement.create(
              sha: "a7f3bb583423771042fd4ca70c5b10cb11afa9692387253f341cc83852962066",
              account_id: mt940_bank_statement.account.id,
              settled: false
            )
            upcoming_flag = false

            described_class.from_bank_statement(mt940_bank_statement, upcoming_flag)

            expect(Statement.last.settled).to be true
          end

          it "marks the statement as settled when the statement is not present" do
            mt940_bank_statement = Fabricate(:mt940_statement)
            upcoming_flag = false

            described_class.from_bank_statement(mt940_bank_statement, upcoming_flag)

            expect(Statement.last.settled).to be true
          end
        end

        context "when the import is triggered as upcoming" do
          it "does not mark the statement as settled" do
            mt940_bank_statement = Fabricate(:mt940_statement)
            upcoming_flag = true

            described_class.from_bank_statement(mt940_bank_statement, upcoming_flag)

            expect(Statement.last.settled).to be false
          end
        end
      end

      # TODO: Check with @namxam why this was done in the first place
      # context 'identical consecutive entries in bank statements' do
      #   let(:mt940) { File.read('spec/fixtures/duplicated_entries.mt940') }

      #   it 'imports both entries' do
      #     bank_statement = ImportBankStatement.from_mt940(mt940, account)
      #     expect { described_class.from_bank_statement(bank_statement) }.to change(Statement, :count).by(2)
      #   end
      # end

      describe "camt bank statement import" do
        context "with trx ids" do
          let(:camt) { File.read("spec/fixtures/camt_statement_with_trx_ids.xml") }

          it "imports camt statements" do
            parsed_camt = SepaFileParser::String.parse(camt).statements
            bank_statement = ImportBankStatement.process(parsed_camt.first, camt_account)
            expect { described_class.from_bank_statement(bank_statement) }.to change { Statement.count }.by(4)
          end
        end

        context "without trx ids" do
          let(:camt) { File.read("spec/fixtures/camt_statement.xml") }

          it "imports camt statements" do
            parsed_camt = SepaFileParser::String.parse(camt).statements
            bank_statement = ImportBankStatement.process(parsed_camt.first, camt_account)
            expect { described_class.from_bank_statement(bank_statement) }.to change { Statement.count }.by(4)
          end
        end

        context "with trx ids" do
          let(:camt) { File.read("spec/fixtures/camt_statement_with_trx_ids.xml") }
          let(:parsed_camt) { SepaFileParser::String.parse(camt).statements }
          let(:old_parsed_camt) { CamtParser::String.parse(camt).statements }
          let(:bank_statement) { ImportBankStatement.process(parsed_camt.first, camt_account) }

          subject { described_class.from_bank_statement(bank_statement) }

          it "imports camt statements" do
            expect { subject }.to change { Statement.count }.by(4)
          end

          it "writes transactions id" do
            subject
            expect(Statement.find(tx_id: "FOO-BAR4711-13-37-13.37.47.110815")).to be_present
          end
        end
      end

      describe ".link_statement_to_transaction" do
        let(:statement) { Statement.create(eref: "eref-123", account_id: account.id) }

        def exec_link_action
          described_class.link_statement_to_transaction(account, statement)
        end

        context "no transaction could be found" do
          it "does not trigger a webhook" do
            expect(Event).to_not receive(:statement_created)
            exec_link_action
          end
        end

        context "transaction exists" do
          let!(:transaction) { Transaction.create(account_id: account.id, eref: statement.eref) }
          let(:event) { object_double(Event).as_stubbed_const }

          context "statement is a credit" do
            before { statement.update(debit: false) }

            it "sets correct transaction state" do
              expect_any_instance_of(Transaction).to receive(:update_status).with("credit_received")
              exec_link_action
            end
          end

          context "statement is a debit" do
            before { statement.update(debit: true) }

            it "sets correct transaction state" do
              expect_any_instance_of(Transaction).to receive(:update_status).with("debit_received")
              exec_link_action
            end
          end
        end
      end

      describe "duplicates" do
        let(:mt940) { File.read("spec/fixtures/similar_but_not_dup_transactions.mt940") }
        let(:mt940b) { File.read("spec/fixtures/dup_whitespace_transaction.mt940") }
        let(:bank_statement) { ImportBankStatement.from_mt940(mt940, account) }

        it "does not import same transaction with different whitespaces in reference" do
          bank_statement = ImportBankStatement.from_mt940(mt940b, account)
          expect { described_class.from_bank_statement(bank_statement) }.to change(Statement, :count).by(1)
        end
      end
    end
  end
end
