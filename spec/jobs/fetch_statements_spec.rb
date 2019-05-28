# frozen_string_literal: true

require 'spec_helper'
require 'active_support/all'

module Box
  module Jobs
    RSpec.describe FetchStatements do
      subject(:job) { described_class.new }
      let(:account) { Account.create(host: 'HOST', iban: 'iban1234567') }
      let!(:ebics_user) { account.add_ebics_user(signature_class: 'T', activated_at: 1.day.ago) }

      describe '.for_account' do
        it 'fetches statement for a single account' do
          expect_any_instance_of(described_class).to receive(:fetch_for_account).with(account.id)
          described_class.for_account(account.id)
        end
      end

      describe '#perform' do
        it 'fetches statements for every submitted account' do
          allow(job).to receive(:fetch_for_account)
          job.perform(account_ids: [1, 2, 3])
        end

        it 'sets default daterange if not provided' do
          allow(job).to receive(:fetch_for_account).and_return(true)
          job.perform(account_ids: [1, 2, 3])
          expect(job.from).to eql(30.days.ago.to_date)
          expect(job.to).to eql(Date.today)
        end

        it 'uses all account ids if none provided' do
          3.times do
            Account.create.tap { |account| EbicsUser.create(account: account, activated_at: Time.now) }
          end

          expect(Account).to receive(:all_active_ids).and_return([])
          job.perform({})
        end
      end

      describe '.fetch_new_statements' do
        let(:client) { double('Epics Client') }

        before do
          account.imported_at!(1.day.ago)
          allow_any_instance_of(EbicsUser).to receive(:client) { client }
          allow(client).to receive(:STA).and_return(File.read('spec/fixtures/mt940.txt'))
          allow(Account).to receive(:[]).and_return(double('account', organization: double('orga', webhook_token: 'token')))

          allow(BusinessProcesses::ImportBankStatement).to receive(:from_cmxl).and_call_original
          allow(BusinessProcesses::ImportStatements).to receive(:from_bank_statement).and_call_original
        end

        it 'imports all bank statements' do
          included_bank_statements = 4
          job.fetch_for_account(account.id)
          expect(BusinessProcesses::ImportBankStatement).to have_received(:from_cmxl).exactly(included_bank_statements).times
        end

        it 'imports all statements for all bank statements' do
          bank_statements_for_this_account = 3 # One bank statement is for another account, such as a sub-account
          job.fetch_for_account(account.id)
          expect(BusinessProcesses::ImportStatements).to have_received(:from_bank_statement).exactly(bank_statements_for_this_account).times
        end

        context 'with timeframe' do
          subject(:job) { described_class.new(from: Date.new(2015, 12, 1), to: Date.new(2015, 12, 31)) }

          def call_job
            job.fetch_for_account(account.id)
          end

          it 'fetches statements from remote server' do
            call_job
            expect(account.transport_client).to have_received(:STA).with('2015-12-01', '2015-12-31')
          end

          it 'does not alter date when last import happened' do
            call_job
            expect_any_instance_of(Account).to_not receive(:imported_at!)
            call_job
          end
        end

        context 'without timeframe' do
          def exec_process
            job.fetch_for_account(account.id)
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
