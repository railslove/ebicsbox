module Epics
  module Box
    RSpec.describe Queue do

      let(:client) { described_class.client }

      describe '.client' do
        it 'returns an instance of a beanstalk client' do
          expect(described_class.client).to be_an_instance_of(Beaneater)
        end
      end

      describe '.fetch_account_statements' do
        let(:tube) { client.tubes[Queue::STA_TUBE] }

        before { tube.clear }

        it 'puts a new message onto the STA queue' do
          expect { described_class.fetch_account_statements }.to change { tube.peek(:ready) }
        end

        it 'puts only the provided account id onto the job' do
          described_class.fetch_account_statements(1)
          expect(tube.peek(:ready).body).to eq(account_ids: [1])
        end

        it 'puts all provided account ids onto the job' do
          described_class.fetch_account_statements([1, 2])
          expect(tube.peek(:ready).body).to eq(account_ids: [1, 2])
        end

        it 'puts all existing account ids onto the job if none is provided' do
          accounts = Array.new(3).map { Account.create }
          described_class.fetch_account_statements
          expect(tube.peek(:ready).body).to eq(account_ids: accounts.map(&:id))
        end
      end

      describe '.update_processing_status' do
        let(:tube) { client.tubes[Queue::ORDER_TUBE] }

        before { tube.clear }

        context 'no job currently queued' do
          it 'puts a new message onto the check orders queue' do
            expect { described_class.update_processing_status }.to change { tube.peek(:delayed) }
          end

          it 'puts only the provided account id onto the job' do
            described_class.update_processing_status(1)
            expect(tube.peek(:delayed).body).to match hash_including(account_ids: [1])
          end

          it 'puts all provided account ids onto the job' do
            described_class.update_processing_status([1, 2])
            expect(tube.peek(:delayed).body).to match hash_including(account_ids: [1, 2])
          end

          it 'puts all existing account ids onto the job if none is provided' do
            accounts = Array.new(3).map { Account.create }
            described_class.update_processing_status
            expect(tube.peek(:delayed).body).to match hash_including(account_ids: accounts.map(&:id))
          end
        end

        context 'job already queued' do
          it 'does not queue another job' do
            described_class.update_processing_status
            expect { described_class.update_processing_status }.to_not change { tube.peek(:delayed).id }
          end
        end
      end

      describe '#with_error_logging' do
        let(:logger) { double('Logger', error: true) }
        let(:exception) { StandardError.new('test') }

        it 'returns the original result' do
          expect(subject.with_error_logging { 'ok' }).to eq('ok')
        end

        it 're-raises any exception raised in its code block' do
          expect { subject.with_error_logging { raise exception } }.to raise_error(exception)
        end

        it 'logs any exception messages' do
          subject.logger = logger
          subject.with_error_logging { raise exception } rescue ''
          expect(logger).to have_received(:error).with("[Queue] Failed job. message='test'")
        end
      end
    end
  end
end
