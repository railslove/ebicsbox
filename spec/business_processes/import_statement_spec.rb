require 'active_support/all'
require 'cmxl'

require_relative '../../box/models/account'
require_relative '../../box/models/organization'
require_relative '../../box/business_processes/import_bank_statement'
require_relative '../../box/business_processes/import_statements'

module Box
  module BusinessProcesses
    RSpec.describe ImportStatements do
      let(:organization) { Organization.create(name: "Testorga") }
      let(:account) { organization.add_account(host: "HOST", iban: "iban1234567") }
      let(:mt940_fixture) { 'single_valid.mt940' }
      let(:mt940) { File.read("spec/fixtures/#{mt940_fixture}") }

      def clear_all_tubes
        Queue.clear!(Queue::DEBIT_TUBE)
        Queue.clear!(Queue::CREDIT_TUBE)
        Queue.clear!(Queue::ORDER_TUBE)
        Queue.clear!(Queue::STA_TUBE)
        Queue.clear!(Queue::WEBHOOK_TUBE)
        Queue.clear!(Queue::ACTIVATION_TUBE)
      end

      around do |example|
        clear_all_tubes
        example.run
        clear_all_tubes
      end


      it 'creates db statements for each bank statement transaction' do
        bank_statement = ImportBankStatement.from_mt940(mt940, account)
        expect(described_class).to receive(:create_statement).twice
        described_class.from_bank_statement(bank_statement)
      end

      context 'identical consecutive entries in bank statements' do
        let(:mt940_fixture) { 'duplicated_entries.mt940' }

        it 'imports both entries' do
          bank_statement = ImportBankStatement.from_mt940(mt940, account)
          expect { described_class.from_bank_statement(bank_statement) }.to change { Statement.count }.by(2)
        end
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
          described_class.create_statement(account, data, 1, ['seq1', 1])
        end

        context 'the statement was already imported' do
          # This is a precalculated SHA based on our algorythm
          before { Statement.create(sha: 'a83041608974d854ef26f649a2a74c6af9688e327d2c4cf8fdf039f07755b521', account_id: account.id) }

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
    end
  end
end
