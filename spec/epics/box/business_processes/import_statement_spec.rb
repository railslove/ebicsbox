require 'active_support/all'
require 'cmxl'

require_relative '../../../../lib/epics/box/models/account'
require_relative '../../../../lib/epics/box/business_processes/import_bank_statement'
require_relative '../../../../lib/epics/box/business_processes/import_statements'

module Epics
  module Box
    module BusinessProcesses
      RSpec.describe ImportStatements do
        let(:account) { Account.create(host: "HOST", iban: "iban1234567") }
        let(:mt940_fixture) { 'single_valid.mt940' }
        let(:mt940) { File.read("spec/fixtures/#{mt940_fixture}") }

        it 'creates db statements for each bank statement transaction' do
          bank_statement = ImportBankStatement.from_mt940(mt940, account)
          expect(described_class).to receive(:create_statement).twice
          described_class.from_bank_statement(bank_statement)
        end

        describe '.create_statement' do
          let(:data) do
            double('MT940 Transaction',
              information: 'test',
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
                "EREF" => 'my-eref',
                "MREF" => 'my-mref',
                "SVWZ" => 'my-svwz',
                "CRED" => 'my-cred',
              }
            )
          end

          before do
            allow(Account).to receive(:[]).and_return(double('account', organization: double('orga', webhook_token: 'token')))
          end

          def exec_create_action
            described_class.create_statement(account, data)
          end

          context 'the statement was already imported' do
            before { Statement.create(sha: '63feaabebb3f24986f64cc2691cc905ff40e600130aa6fec9e281452e93abb58', account_id: account.id) }

            it 'does not create a statement' do
              expect { exec_create_action }.to_not change{ Statement.count }
            end
          end

          context 'statement is new' do
            it 'extracts subdata from sepa subtree' do
              exec_create_action
              expect(Statement.last.values).to match(hash_including(
                eref: 'my-eref',
                mref: 'my-mref',
                svwz: 'my-svwz',
                creditor_identifier: 'my-cred',
              ))
            end

            it 'creates an event' do
              expect(Event).to receive(:publish).with(:statement_created, anything)
              exec_create_action
            end
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
                expect_any_instance_of(Transaction).to receive(:set_state_from).with('credit_received')
                exec_link_action
              end
            end

            context 'statement is a debit' do
              before { statement.update(debit: true) }

              it 'sets correct transaction state' do
                expect_any_instance_of(Transaction).to receive(:set_state_from).with('debit_received')
                exec_link_action
              end
            end
          end
        end
      end
    end
  end
end
