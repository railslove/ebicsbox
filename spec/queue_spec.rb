# frozen_string_literal: true

module Box
  RSpec.describe Queue do
    describe '.fetch_account_statements' do
      let(:jobs) { Jobs::QueueFetchStatements.jobs }

      it 'puts a new message onto the STA queue' do
        expect { described_class.fetch_account_statements }.to(change { jobs.count })
      end

      it 'puts only the provided account id onto the job' do
        jid = described_class.fetch_account_statements(1)
        job = jobs.find { |j| j['jid'] == jid }
        expect(job['args'].flatten).to match_array([1])
      end

      it 'puts all provided account ids onto the job' do
        jid = described_class.fetch_account_statements([1, 2])
        job = jobs.find { |j| j['jid'] == jid }
        expect(job['args'].flatten).to match_array([1, 2])
      end
    end

    describe '.update_processing_status' do
      let(:jobs) { Jobs::QueueProcessingStatus.jobs }
      let(:tube) { Sidekiq::Queue.new('check.orders') }

      context 'no job currently queued' do
        it 'puts a new message onto the check orders queue' do
          expect { described_class.update_processing_status }.to(change(Jobs::QueueProcessingStatus.jobs, :size))
        end

        it 'puts only the provided account id onto the job' do
          jid = described_class.update_processing_status([1])
          job = jobs.find { |j| j['jid'] == jid }

          expect(job['args'].flatten).to match_array([1])
        end

        it 'puts all provided account ids onto the job' do
          jid = described_class.update_processing_status([1, 2])
          job = jobs.find { |j| j['jid'] == jid }

          expect(job['args'].flatten).to match_array([1, 2])
        end

        it 'puts all existing account ids onto the job if none is provided' do
          Fabricate.times(3, :activated_account)

          account_ids = Account.all_active_ids

          jid = described_class.update_processing_status
          job = jobs.find { |j| j['jid'] == jid }

          expect(job['args'].flatten).to match_array(account_ids)
        end
      end

      context 'job already queued' do
        before do
          Sidekiq::Testing.disable! # disable sidekiq faking mode to write job to schedule queue
          described_class.update_processing_status # enqueue job
        end

        after do
          Sidekiq::Testing.fake! # reenable fake mode
          Sidekiq::ScheduledSet.new.clear # clear scheduled jobs
        end

        it 'does not queue another job' do
          expect { described_class.update_processing_status }.to_not(change { jobs.count })
        end
      end
    end
  end
end
