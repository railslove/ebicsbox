# frozen_string_literal: true

require 'spec_helper'
require 'active_support/all'

module Box
  module Jobs
    RSpec.describe FetchStatements do
      subject(:job) { described_class.new }
      let(:account) { Fabricate(:account, host: 'HOST', iban: 'iban1234567') }
      let!(:ebics_user) { account.add_ebics_user(signature_class: 'T', activated_at: 1.day.ago) }

      describe '#perform' do
        it 'raises error when no account id given' do
          expect { job.perform(nil) }.to raise_error(FetchStatementsError)
        end

        it 'fetches statements for provided account' do
          allow(job).to receive(:fetch_for_account).with(account)
          job.perform(account.id)
        end

        it 'sets default daterange if not provided' do
          allow(job).to receive(:fetch_for_account).and_return(true)
          job.perform(account.id)
          expect(job.from).to eql(7.days.ago.to_date)
          expect(job.to).to eql(Date.today)
        end
      end

      describe '.fetch_new_statements' do
        let(:client) { double('Epics Client') }

        before do
          account.imported_at!(1.day.ago)
          allow_any_instance_of(EbicsUser).to receive(:client) { client }
          allow(client).to receive(:STA).and_return(File.read('spec/fixtures/mt940.txt'))

          allow(BusinessProcesses::ImportBankStatement).to receive(:from_cmxl).and_call_original
          allow(BusinessProcesses::ImportStatements).to receive(:from_bank_statement).and_call_original
        end

        it 'imports all bank statements' do
          included_bank_statements = 4
          job.perform(account.id)
          expect(BusinessProcesses::ImportBankStatement).to have_received(:from_cmxl).exactly(included_bank_statements).times
        end

        it 'imports all statements for all bank statements' do
          bank_statements_for_this_account = 3 # One bank statement is for another account, such as a sub-account
          job.perform(account.id)
          expect(BusinessProcesses::ImportStatements).to have_received(:from_bank_statement).exactly(bank_statements_for_this_account).times
        end

        it 'does nothing when no data is provided' do
          allow(client).to receive(:STA).and_return(nil)

          job.perform(account.id)

          expect(BusinessProcesses::ImportBankStatement).not_to have_received(:from_cmxl)
          expect(BusinessProcesses::ImportStatements).not_to have_received(:from_bank_statement)
        end

        context 'with timeframe' do
          subject(:call_job) do
            described_class.new.perform(account.id, from: Date.new(2015, 12, 1), to: Date.new(2015, 12, 31))
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
          subject(:call_job) do
            described_class.new.perform(account.id)
          end

          it 'fetches statements from remote server' do
            call_job
            expect(account.transport_client).to have_received(:STA).with(7.days.ago.to_date.to_s, Date.today.to_s)
          end

          it 'adds info that a new import happened' do
            expect_any_instance_of(Account).to receive(:imported_at!)
            call_job
          end
        end
      end
    end
  end
end
