require 'spec_helper'
require 'active_support/all'

module Box
  module Jobs
    RSpec.describe FetchStatements do
      let(:account) { Account.create(host: "HOST", iban: "iban1234567") }
      let!(:subscriber) { account.add_subscriber(signature_class: 'T', activated_at: 1.day.ago) }

      describe '.process!' do
        it 'fetches statements for every submitted account' do
          allow(described_class).to receive(:fetch_new_statements)
          described_class.process!(account_ids: [1, 2, 3])
          expect(described_class).to have_received(:fetch_new_statements).with(1).with(2).with(3)
        end
      end

      describe '.fetch_new_statements' do
        let(:client) { double('Epics Client') }

        before do
          account.imported_at!(1.day.ago)
          allow_any_instance_of(Subscriber).to receive(:client) { client }
          allow(client).to receive(:STA).and_return(File.read('spec/fixtures/mt940.txt'))
          allow(Account).to receive(:[]).and_return(double('account', organization: double('orga', webhook_token: 'token')))

          allow(BusinessProcesses::ImportBankStatement).to receive(:from_cmxl).and_call_original
          allow(BusinessProcesses::ImportStatements).to receive(:from_bank_statement).and_call_original
        end

        it 'imports all bank statements' do
          included_bank_statements = 4
          described_class.fetch_new_statements(account.id)
          expect(BusinessProcesses::ImportBankStatement).to have_received(:from_cmxl).exactly(included_bank_statements).times
        end

        it 'imports all statements for all bank statements' do
          bank_statements_for_this_account = 3 # One bank statement is for another account, such as a sub-account
          described_class.fetch_new_statements(account.id)
          expect(BusinessProcesses::ImportStatements).to have_received(:from_bank_statement).exactly(bank_statements_for_this_account).times
        end

        context 'with timeframe' do
          def exec_process
            described_class.fetch_new_statements(account.id, Date.new(2015, 12, 1), Date.new(2015, 12, 31))
          end

          it 'fetches statements from remote server' do
            exec_process
            expect(account.transport_client).to have_received(:STA).with("2015-12-01", "2015-12-31")
          end

          it 'does not alter date when last import happened' do
            exec_process
            expect_any_instance_of(Account).to_not receive(:imported_at!)
            exec_process
          end
        end

        context 'without timeframe' do
          def exec_process
            described_class.fetch_new_statements(account.id)
          end

          it 'fetches statements from remote server' do
            exec_process
            expect(account.transport_client).to have_received(:STA).with(30.days.ago.to_date.to_s, Date.today.to_s)
          end

          it 'adds info that a new import happened' do
            expect_any_instance_of(Account).to receive(:imported_at!)
            exec_process
          end
        end
      end
    end
  end
end
