module Box
  module Jobs
    RSpec.describe Credit do
      describe '.process!' do
        let(:last_transaction) { Transaction.last }
        let(:message) do
          {
            amount: 100,
            instrument: 'CORE',
            eref: '123',
            account_id: 321,
            payload: 'PAIN',
          }
        end

        before do
          allow_any_instance_of(Transaction).to receive(:execute!).and_return(true)
          allow(Queue).to receive(:update_processing_status)
        end

        it 'creates a transaction' do
          expect { described_class.process!(message) }.to change { Transaction.count }.by(1)
        end

        it 'sets correct order type' do
          described_class.process!(message)
          expect(last_transaction.type).to eq('credit')
        end

        it 'sets correct amount' do
          described_class.process!(message)
          expect(last_transaction.amount).to eq(100)
        end

        it 'encodes the pain payload with base 64' do
          encoded_payload = Base64.strict_decode64('PAIN')
          described_class.process!(message)
          expect(last_transaction.payload).to eq(encoded_payload)
        end

        it 'executes the created transaction' do
          expect_any_instance_of(Transaction).to receive(:execute!)
          described_class.process!(message)
        end

        it 'tells the system to check for job processing status' do
          described_class.process!(message)
          expect(Queue).to have_received(:update_processing_status).with(321)
        end

        it 'logs an info message' do
          expect(Box.logger).to receive(:info).with(/\[Jobs::Credit\] Created credit! transaction_id=\d+/)
          described_class.process!(message)
        end
      end
    end
  end
end
