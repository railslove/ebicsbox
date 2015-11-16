module Epics
  module Box
    RSpec.describe Queue do

      let(:client) { described_class.client }

      def clear_all_tubes
        client.tubes[Queue::DEBIT_TUBE].clear
        client.tubes[Queue::CREDIT_TUBE].clear
        client.tubes[Queue::ORDER_TUBE].clear
        client.tubes[Queue::STA_TUBE].clear
        client.tubes[Queue::WEBHOOK_TUBE].clear
        client.tubes[Queue::ACTIVATION_TUBE].clear
      end

      around do |example|
        clear_all_tubes
        example.run
        clear_all_tubes
      end

      describe '.client' do
        it 'returns an instance of a beanstalk client' do
          expect(described_class.client).to be_an_instance_of(Beaneater)
        end
      end

      describe '.fetch_account_statements' do
        let(:tube) { client.tubes[Queue::STA_TUBE] }

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
          accounts = Array.new(3).map do
            Account.create.tap { |account| Subscriber.create(account: account, activated_at: Time.now) }
          end
          described_class.fetch_account_statements
          expect(tube.peek(:ready).body).to eq(account_ids: accounts.map(&:id))
        end
      end

      describe '.check_subscriber_activation' do
        let(:tube) { client.tubes[Queue::ACTIVATION_TUBE] }

        context 'delay check by default' do
          it 'puts a new message onto the activation queue' do
            expect { described_class.check_subscriber_activation(1) }.to change { tube.peek(:delayed) }
          end

          it 'puts only provided account id onto job' do
            described_class.check_subscriber_activation(1)
            expect(tube.peek(:delayed).body).to eq(subscriber_id: 1)
          end

          it 'does not put anything on immediate execution tube' do
            expect { described_class.check_subscriber_activation(1) }.to_not change { tube.peek(:ready) }
          end
        end

        context 'can schedule immidiate check' do
          it 'puts a new message onto the activation queue' do
            expect { described_class.check_subscriber_activation(1, false) }.to change { tube.peek(:ready) }
          end

          it 'puts only provided account id onto job' do
            described_class.check_subscriber_activation(1, false)
            expect(tube.peek(:ready).body).to eq(subscriber_id: 1)
          end

          it 'does not put anything on delayed execution tube' do
            expect { described_class.check_subscriber_activation(1, false) }.to_not change { tube.peek(:delayed) }
          end
        end
      end

      describe '.update_processing_status' do
        let(:tube) { client.tubes[Queue::ORDER_TUBE] }

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
            accounts = Array.new(3).map do
              Account.create.tap { |account| Subscriber.create(account: account, activated_at: Time.now) }
            end
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

      describe '#process!' do
        let(:payload) { { some: 'data' } }

        it 'registers debit jobs' do
          expect(Jobs::Debit).to receive(:process!).with(payload) { raise Beaneater::AbortProcessingError }
          described_class.execute_debit(payload)
          subject.process!
        end

        it 'registers credit jobs' do
          expect(Jobs::Credit).to receive(:process!).with(payload) { raise Beaneater::AbortProcessingError }
          described_class.execute_credit(payload)
          subject.process!
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
