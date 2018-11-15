# frozen_string_literal: true

module Box
  RSpec.describe Queue do
    let(:scheduled_jobs) { Sidekiq::ScheduledSet.new }

    before(:each) do
      Sidekiq::Queue.all.each(&:clear)
      scheduled_jobs.clear
    end

    describe '.fetch_account_statements' do
      let(:tube) { Sidekiq::Queue.new('check.statements') }

      it 'puts a new message onto the STA queue' do
        expect { described_class.fetch_account_statements }.to change { tube.size }
      end

      it 'puts only the provided account id onto the job' do
        described_class.fetch_account_statements(1)
        expect(tube.first.args).to include('account_ids' => [1])
      end

      it 'puts all provided account ids onto the job' do
        described_class.fetch_account_statements([1, 2])
        expect(tube.first.args).to include('account_ids' => [1, 2])
      end

      it 'puts all existing account ids onto the job if none is provided' do
        accounts = Array.new(3).map do
          Account.create.tap { |account| Subscriber.create(account: account, activated_at: Time.now) }
        end
        described_class.fetch_account_statements
        expect(tube.first.args).to include('account_ids' => accounts.map(&:id))
      end
    end

    describe '.check_subscriber_activation' do
      let(:tube) { Sidekiq::Queue.new('check.activations') }

      context 'delay check by default' do
        it 'schedules a new job' do
          expect { described_class.check_subscriber_activation(1, 120) }.to change { scheduled_jobs.size }
        end

        it 'schedules by given time' do
          jid = described_class.check_subscriber_activation(1, 45)
          job = scheduled_jobs.find { |j| j.jid == jid }
          creation_time = Time.at(job.created_at)
          execution_time = Time.at(job.score)

          expect(execution_time - creation_time).to be_within(0.1).of(45)
        end

        it 'puts only provided account id onto job' do
          described_class.check_subscriber_activation(1, 0)
          expect(tube.first.args).to include('subscriber_id' => 1)
        end

        it 'does not queue it right away' do
          expect { described_class.check_subscriber_activation(1, 120) }.not_to change { tube.size }
        end
      end
    end

    describe '.update_processing_status' do
      let(:tube) { Sidekiq::Queue.new('check.orders') }

      context 'no job currently queued' do
        it 'puts a new message onto the check orders queue' do
          expect { described_class.update_processing_status }.to change { scheduled_jobs.size }
        end

        it 'puts only the provided account id onto the job' do
          jid = described_class.update_processing_status(1)
          job = scheduled_jobs.find { |j| j.jid == jid }
          expect(job.args).to include('account_ids' => [1])
        end

        it 'puts all provided account ids onto the job' do
          jid = described_class.update_processing_status([1, 2])
          job = scheduled_jobs.find { |j| j.jid == jid }

          expect(job.args).to include('account_ids' => [1, 2])
        end

        it 'puts all existing account ids onto the job if none is provided' do
          accounts = Array.new(3).map do
            Account.create.tap { |account| Subscriber.create(account: account, activated_at: Time.now) }
          end
          jid = described_class.update_processing_status

          job = scheduled_jobs.find { |j| j.jid == jid }
          expect(job.args).to include('account_ids' => accounts.map(&:id))
        end
      end

      context 'job already queued' do
        before { described_class.update_processing_status }
        it 'does not queue another job' do
          expect { described_class.update_processing_status }.to_not change { scheduled_jobs.size }
        end
      end
    end
  end
end
