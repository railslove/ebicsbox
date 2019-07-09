# frozen_string_literal: true

require 'spec_helper'
require 'active_support/all'

module Box
  module Jobs
    RSpec.describe FetchUpcomingStatements do
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
          expect(job.send(:safe_from)).to eql(Date.today)
          expect(job.send(:safe_to)).to eql(30.days.from_now.to_date)
        end

        it 'uses all account ids if none provided' do
          expect(Account).to receive(:all_active_ids).and_return([])
          job.perform({})
        end

        it 'raises error when account uses camt instead of mt940' do
          account.update(statements_format: 'camt53')
          expect(account).not_to receive(:transport_client)
          expect(Box.logger).to(
            receive(:info)
              .with("[Jobs::FetchUpcomingStatements] Skip VMK for #{account.id}. Currently only MT942 is supported")
          )

          job.perform({})
        end
      end

      describe '.fetch_for_account' do
        let(:client) { double('Epics Client') }

        def call_job
          job.fetch_for_account(account.id)
        end

        before do
          allow_any_instance_of(EbicsUser).to receive(:client) { client }
          allow(client).to receive(:VMK).and_return(File.read('spec/fixtures/mt942.txt'))
          allow(Account).to(
            receive(:[]).and_return(double('account', organization: double('orga', webhook_token: 'token')))
          )

          allow(BusinessProcesses::ImportBankStatement).to receive(:from_cmxl).and_call_original
          allow(BusinessProcesses::ImportStatements).to receive(:from_bank_statement).and_call_original
        end

        it 'imports all bank statements' do
          included_vmk = 3
          call_job
          expect(BusinessProcesses::ImportBankStatement).to(
            have_received(:from_cmxl).exactly(included_vmk).times
          )
        end

        it 'imports all statements for all bank statements' do
          bank_statements_for_this_account = 3 # One bank statement is for another account, such as a sub-account
          call_job
          expect(BusinessProcesses::ImportStatements).to(
            have_received(:from_bank_statement).exactly(bank_statements_for_this_account).times
          )
        end

        context 'with timeframe' do
          subject(:job) { described_class.new(from: Date.new(2019, 6, 1), to: Date.new(2019, 10, 31)) }

          it 'fetches statements from remote server' do
            call_job
            expect(account.transport_client).to have_received(:VMK).with('2019-06-01', '2019-10-31')
          end
        end

        context 'without timeframe' do
          it 'fetches statements from remote server' do
            call_job
            expect(account.transport_client).to(
              have_received(:VMK).with(Date.today.to_s, 30.days.from_now.to_date.to_s)
            )
          end
        end
      end
    end
  end
end
