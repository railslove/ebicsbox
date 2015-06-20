module Epics
  module Box
    module Jobs
      RSpec.describe Debit do
        describe '.process!' do
          let(:transaction) { double('Transaction', execute!: true, id: 1) }
          let(:message) do
            {
              instrument: 'CORE',
              eref: '123',
              account_id: '321',
              payload: 'PAIN',
            }
          end

          before { allow(Transaction).to receive(:create).and_return(transaction) }

          it 'creates a transaction' do
            Debit.process!(message)
            expect(Transaction).to have_received(:create)
          end

          it 'sets valid order type based on used instrument' do
            Debit.process!(message)
            expect(Transaction).to have_received(:create).with(hash_including(order_type: :CDD))
          end

          it 'encodes the pain payload with base 64' do
            encoded_payload = Base64.strict_decode64('PAIN')
            Debit.process!(message)
            expect(Transaction).to have_received(:create).with(hash_including(payload: encoded_payload))
          end

          it 'executes the created transaction' do
            Debit.process!(message)
            expect(transaction).to have_received(:execute!)
          end

          it 'tells the system to check for job processing status' do
            expect(Queue).to receive(:check_accounts)
            Debit.process!(message)
          end

          it 'logs an info message' do
            expect(Box.logger).to receive(:info).with('[Jobs::Debit] Created debit! transaction_id=1')
            Debit.process!(message)
          end
        end
      end
    end
  end
end
