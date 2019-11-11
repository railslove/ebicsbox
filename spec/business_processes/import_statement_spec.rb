# frozen_string_literal: true

require 'active_support/all'
require 'cmxl'

require_relative '../../box/models/account'
require_relative '../../box/models/organization'
require_relative '../../box/business_processes/import_bank_statement'
require_relative '../../box/business_processes/import_statements'

module Box
  module BusinessProcesses
    RSpec.describe ImportStatements do
      let(:organization) { Fabricate(:organization) }
      let(:account) { organization.add_account(host: 'HOST', iban: 'iban1234567') }
      let(:camt_account) { organization.add_account(host: 'HOST', iban: 'iban1234567', statements_format: 'camt53') }
      let(:camt_fixture) { 'camt_statement.xml' }
      let(:camt) { File.read("spec/fixtures/#{camt_fixture}") }
      let(:mt940) { File.read('spec/fixtures/single_valid.mt940') }

      def clear_all_tubes
        Queue.clear!(Queue::DEBIT_TUBE)
        Queue.clear!(Queue::CREDIT_TUBE)
        Queue.clear!(Queue::ORDER_TUBE)
        Queue.clear!(Queue::STA_TUBE)
        Queue.clear!(Queue::WEBHOOK_TUBE)
        Queue.clear!(Queue::ACTIVATION_TUBE)
      end

      before(:each) { Sidekiq::Queue.all.each(&:clear) }

      it 'creates db statements for each bank statement transaction' do
        bank_statement = ImportBankStatement.from_mt940(mt940, account)
        expect(described_class).to receive(:create_statement).twice
        described_class.from_bank_statement(bank_statement)
      end

      # TODO: Check with @namxam why this was done in the first place
      # context 'identical consecutive entries in bank statements' do
      #   let(:mt940) { File.read('spec/fixtures/duplicated_entries.mt940') }

      #   it 'imports both entries' do
      #     bank_statement = ImportBankStatement.from_mt940(mt940, account)
      #     expect { described_class.from_bank_statement(bank_statement) }.to change(Statement, :count).by(2)
      #   end
      # end

      describe '.create_statement' do
        let(:bank_statement) do
          double(
            id: 42,
            account: account,
            remote_account: 'FooBar/4711',
            sequence: '47/11',
            opening_balance: 123,
            closing_balance: 456,
            fetched_on: '2015-06-20'
          )
        end

        let(:data) do
          double('MT940 Transaction',
                 date: '2015-06-20',
                 entry_date: '2015-06-20',
                 amount_in_cents: 100_24,
                 sign: 1,
                 debit?: true,
                 swift_code: 'swift_code',
                 reference: 'reference',
                 bank_reference: 'bank_reference',
                 bic: 'bic',
                 iban: 'iban',
                 name: 'name',
                 information: 'information',
                 description: 'description',
                 sha: 'balbalblabladslflasdfk',
                 sepa: {
                   'EREF' => 'my-eref',
                   'MREF' => 'my-mref',
                   'SVWZ' => 'my-svwz',
                   'CRED' => 'my-cred'
                 })
        end

        before do
          allow(Account).to receive(:[]).and_return(double('account', organization: double('orga', webhook_token: 'token')))
        end

        def exec_create_action
          described_class.create_statement(bank_statement, data)
        end

        context 'the statement was already imported' do
          # This is a precalculated SHA based on our algorithm
          before { Statement.create(sha: '19404d0568b99397f405fdf22c56e58c6d6c781d0fab8fd2bb0e066f3fe29380', account_id: account.id) }

          it 'does not create a statement' do
            expect { exec_create_action }.to_not change(Statement, :count)
          end
        end

        context 'statement is new' do
          it 'extracts subdata from sepa subtree' do
            exec_create_action
            expect(Statement.last.values).to match(hash_including(
                                                     eref: 'my-eref',
                                                     mref: 'my-mref',
                                                     svwz: 'my-svwz',
                                                     creditor_identifier: 'my-cred'
                                                   ))
          end

          it 'creates an event' do
            expect(Event).to receive(:publish).with(:statement_created, anything)
            exec_create_action
          end
        end
      end

      describe 'duplicated bank statement number' do
        let!(:cmxl_2016) { File.read('spec/fixtures/duplicated_sequence_number_2016.mt940') }
        let!(:cmxl_2017) { File.read('spec/fixtures/duplicated_sequence_number_2017.mt940') }

        it 'imports even if statement number is duplicated' do
          bank_statement = ImportBankStatement.from_mt940(cmxl_2016, account)
          expect { described_class.from_bank_statement(bank_statement) }.to change { Statement.count }.by(4)
          bank_statement = ImportBankStatement.from_mt940(cmxl_2017, account)
          expect { described_class.from_bank_statement(bank_statement) }.to change { Statement.count }.by(2)
        end
      end

      describe 'camt bank statement import' do
        it 'imports camt statements' do
          parsed_camt = CamtParser::String.parse(camt).statements
          bank_statement = ImportBankStatement.from_cmxl(parsed_camt.first, camt_account)
          expect { described_class.from_bank_statement(bank_statement) }.to change { Statement.count }.by(4)
        end
      end

      describe '.link_statement_to_transaction' do
        let(:statement) { Statement.create(eref: 'eref-123', account_id: account.id) }

        def exec_link_action
          described_class.link_statement_to_transaction(account, statement)
        end

        context 'no transaction could be found' do
          it 'does not trigger a webhook' do
            expect(Event).to_not receive(:statement_created)
            exec_link_action
          end
        end

        context 'transaction exists' do
          let!(:transaction) { Transaction.create(account_id: account.id, eref: statement.eref) }
          let(:event) { object_double(Event).as_stubbed_const }

          context 'statement is a credit' do
            before { statement.update(debit: false) }

            it 'sets correct transaction state' do
              expect_any_instance_of(Transaction).to receive(:update_status).with('credit_received')
              exec_link_action
            end
          end

          context 'statement is a debit' do
            before { statement.update(debit: true) }

            it 'sets correct transaction state' do
              expect_any_instance_of(Transaction).to receive(:update_status).with('debit_received')
              exec_link_action
            end
          end
        end
      end

      describe 'duplicates' do
        let(:mt940) { File.read('spec/fixtures/similar_but_not_dup_transactions.mt940') }
        let(:mt940b) { File.read('spec/fixtures/dup_whitespace_transaction.mt940') }
        let(:bank_statement) { ImportBankStatement.from_mt940(mt940, account) }

        it 'importes both statements' do
          expect { described_class.from_bank_statement(bank_statement) }.to(
            change(Statement, :count).by(2)
          )
        end

        it 'recognizes duplicates when importing data again' do
          expect {
            described_class.from_bank_statement(bank_statement)
            described_class.from_bank_statement(bank_statement)
          }.to(change(Statement, :count).by(2))
        end

        it 'does not import same transaction with different whitespaces in reference' do
          bank_statement = ImportBankStatement.from_mt940(mt940b, account)
          expect { described_class.from_bank_statement(bank_statement) }.to change(Statement, :count).by(1)
        end
      end

      describe 'importing VMK' do
        let(:mt942) { File.read('spec/fixtures/single_valid.mt942') }
        let(:bank_statement) { ImportBankStatement.from_mt940(mt942, account) }
        let(:statement) { Box::Statement.first(sha: 'be3a41c6262f85b409fefee10d7515893301411c765ffbf708a36694a365c213') }

        it 'imports each statement' do
          expect(described_class).to receive(:create_statement).once
          described_class.from_bank_statement(bank_statement, upcoming: true)
        end

        it 'marks statements as unsettled' do
          described_class.from_bank_statement(bank_statement, upcoming: true)
          expect(statement.settled).to be_falsey
        end

        context 'importing mt940 statement that was previously imported via vmk' do
          let(:mt940_bank_statement) { ImportBankStatement.from_mt940(mt940, account) }
          let(:mt940_bank_transactions) { described_class.parse_bank_statement(mt940_bank_statement) }

          before { described_class.from_bank_statement(bank_statement, upcoming: true) }

          it 'does not create a new statement' do
            transaction = mt940_bank_transactions.first
            expect(described_class.create_statement(mt940_bank_statement, transaction)).to be_falsey
          end

          it 'does update statement from VMK to be settled' do
            transaction = mt940_bank_transactions.first
            described_class.create_statement(mt940_bank_statement, transaction)
            expect(statement.settled).to be_truthy
          end

          it 'still imports remaining statements' do
            transaction = mt940_bank_transactions.last
            expect(described_class.create_statement(mt940_bank_statement, transaction)).to be_truthy
          end
        end
      end
    end
  end
end
