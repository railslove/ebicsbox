module Box
  module Models
    RSpec.describe Transaction do
      describe '#set_state_from' do
        context 'status changed' do
          skip 'triggers a changed event' do
            subject.status = 'created'
            expect(Event).to receive(:transaction_updated)
            subject.set_state_from 'file_upload'
          end
        end

        context 'status did not change' do
          it 'does not trigger a changed event' do
            subject.status = 'created'
            expect(Event).to_not receive(:transaction_updated)
            subject.set_state_from 'test'
          end
        end
      end

      describe '#execute!' do
        let(:client) { double('Client') }
        let(:account) { Account.create }
        let(:user) { User.create }
        let!(:subscriber) { user.add_subscriber(account: account) }
        subject(:transaction) { account.add_transaction(user: user, order_type: 'test', payload: 'my-pain') }

        before do
          allow_any_instance_of(Subscriber).to receive(:client).and_return(client)
          allow(client).to receive(:public_send) do |type, pain|
            ["transaction-#{type}", "order-#{type}"]
          end
        end

        it 'does not allow to execute transactions more than once' do
          transaction.ebics_transaction_id = '123'
          transaction.execute!
          expect(client).to_not have_received(:public_send)
        end

        it 'store the ebics order id' do
          transaction.execute!
          expect(transaction.ebics_order_id).to eq('order-test')
        end

        it 'store the ebics transaction id' do
          transaction.execute!
          expect(transaction.ebics_transaction_id).to eq('transaction-test')
        end

        it 'executes a ebics call with stored PAIN payload' do
          transaction.execute!
          expect(client).to have_received(:public_send).with(anything, 'my-pain')
        end

        it 'executes the correct ebics call' do
          transaction.execute!
          expect(client).to have_received(:public_send).with('test', anything)
        end
      end
    end
  end
end
