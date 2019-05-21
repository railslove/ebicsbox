require "epics"

module Box
  module Models
    RSpec.describe Transaction do

      it 'automatically sets created_at timestamp' do
        trx = Transaction.create
        expect(trx.reload.created_at).to be_kind_of(Time)
      end

      describe 'public api' do
        describe 'instance' do
          subject { described_class.new }

          it { is_expected.to respond_to(:parsed_payload) }
        end
      end

      describe '#update_status' do
        subject { Transaction.create(type: 'debit', status: 'created') }

        it 'tracks no changes in history' do
          expect{ subject.update_status("test") }.to_not change{ subject.reload.history }
        end

        describe 'when the status actually changes' do
          subject { Transaction.create(type: 'debit', status: 'created', account_id: account.id) }
          let(:account) { Fabricate(:account) }

          before do
            allow(Event).to receive(:debit_status_changed)
          end

          it 'publishes an event when status changes' do
            subject.update_status("file_upload")

            expect(Event).to have_received(:debit_status_changed).with(subject)
          end

          it 'tracks changes in history' do
            expect(subject.history).to be_empty

            subject.update_status("file_upload")

            expect(subject.reload.history).to include(hash_including('at', 'status', 'reason'))
          end
          it 'returns new status', verify_stubs: false do
            subject.status = 'created'
            result = subject.update_status('file_upload')
            expect(result).to eq('file_upload')
          end

          context 'status changed' do
            it 'triggers a changed event', verify_stubs: false do
              subject.status = 'created'
              subject.update_status 'file_upload'
            end
          end
        end

        context 'status did not change' do
          it 'does not trigger a changed event' do
            subject.status = 'created'
            subject.update_status 'test'
          end
        end
      end

      describe "#get_status", verify_stubs: false do
        it "returns previous status on unexpected change" do
          subject.status = 'created'
          expect(subject.get_status("hello")).to eq("created")
        end

        it "returns new status on expected change" do
          subject.status = 'created'
          expect(subject.get_status("file_upload")).to eq("file_upload")
        end
      end

      describe '#execute!' do
        let(:client) { double('Client') }
        let(:account) { Account.create }
        let(:user) { User.create }
        let!(:ebics_user) { account.add_ebics_user(user: user) }
        subject(:transaction) { account.add_transaction(user: user, order_type: 'test', payload: 'my-pain', type: 'debit') }

        before do
          allow_any_instance_of(EbicsUser).to receive(:client).and_return(client)
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

        describe 'ebics call fails' do
          before do
            allow(client).to receive(:public_send).and_raise(Epics::Error::TechnicalError.new('061099'))
          end

          it 'updates the status' do
            expect{ transaction.execute! }.to change(transaction, :status).to('failed')
          end

          it 'updates the history' do
            expect{ transaction.execute! }.to change { transaction.history.to_a }.to(
              [hash_including(reason: '061099/EBICS_INTERNAL_ERROR - Internal EBICS error')]
            )
          end
        end
      end

      describe '#parsed_payload' do
        subject(:transaction) { Transaction.create(payload: 'my-pain') }

        it 'uses the pain parser to get its data' do
          expect(Pain).to receive(:from_xml).with('my-pain')
          transaction.parsed_payload
        end

        it 'returns nil on invalid data' do
          transaction.payload = ""
          expect(transaction.parsed_payload).to be_nil
        end
      end
    end
  end
end
