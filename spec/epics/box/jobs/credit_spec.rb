module Epics
  module Box
    module Jobs
      RSpec.describe Credit do
        describe '.process!' do
          let(:transaction) { double('Transaction', execute!: true, id: 1) }
          let(:message) do
            {
              instrument: 'CORE',
              eref: '123',
              account_id: 321,
              payload: 'PAIN',
            }
          end

          before do
            allow(Transaction).to receive(:create).and_return(transaction)
            allow(Queue).to receive(:update_processing_status)
          end

          it 'creates a transaction' do
            described_class.process!(message)
            expect(Transaction).to have_received(:create)
          end

          it 'sets correct order type' do
            described_class.process!(message)
            expect(Transaction).to have_received(:create).with(hash_including(order_type: :CCT))
          end

          it 'encodes the pain payload with base 64' do
            encoded_payload = Base64.strict_decode64('PAIN')
            described_class.process!(message)
            expect(Transaction).to have_received(:create).with(hash_including(payload: encoded_payload))
          end

          it 'executes the created transaction' do
            described_class.process!(message)
            expect(transaction).to have_received(:execute!)
          end

          it 'tells the system to check for job processing status' do
            described_class.process!(message)
            expect(Queue).to have_received(:update_processing_status).with(321)
          end

          it 'logs an info message' do
            expect(Box.logger).to receive(:info).with('[Jobs::Credit] Created credit! transaction_id=1')
            described_class.process!(message)
          end
        end
      end
    end
  end
end
