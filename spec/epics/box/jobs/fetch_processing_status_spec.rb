require 'json'

module Epics
  module Box
    module Jobs
      RSpec.describe FetchProcessingStatus do
        describe '.process!' do
          it 'fetches processing status for all provided accounts' do
            expect(described_class).to receive(:remote_records).exactly(3).times.and_return([])
            described_class.process!(account_ids: [1,2,3])
          end

          it 'triggers transaction updates for all records from remote documents' do
            expect(described_class).to receive(:remote_records).with(1).and_return([{ some: 'data' }])
            expect(described_class).to receive(:update_transaction).with(1, { some: 'data' })
            described_class.process!(account_ids: [1])
          end
        end

        describe '.update_transaction' do
          def do_action(order_id = '0001')
            described_class.update_transaction(1, { action: 'test', reason_code: 'none', ids: { 'OrderID' => order_id }})
          end

          context 'transaction with order exists' do
            let!(:transaction) { Transaction.create(ebics_order_id: '0001', status: 'new') }

            it 'updates the transaction status' do
              expect_any_instance_of(Transaction).to receive(:set_state_from).with('test', 'none')
              do_action
            end

            context 'transaction status changed' do
              it 'updates the transaction status' do
                expect_any_instance_of(Transaction).to receive(:set_state_from).and_return('changed')
                do_action
              end
            end

            context 'transaction status did not change' do
              before { allow_any_instance_of(Transaction).to receive(:set_state_from).and_return('new') }

              it 'does not trigger a webhook' do
                expect(Event).to_not receive(:transaction_updated)
                do_action
              end
            end
          end

          context 'no transaction with order id found' do
            it 'logs an info message' do
              expect { do_action('0002') }.to have_logged_message('[Jobs::FetchProcessingStatus] No transactions with order id found. account_id=1 order_id=0002')
            end
          end
        end

        describe '.remote_records' do
          let(:keys) { JSON.parse(File.read('spec/fixtures/account.key')) }
          let!(:account) { Account.create(key: JSON.dump(keys), passphrase: 'secret', user: 'EBIX', partner: 'EBICS', url: 'https://194.180.18.30/ebicsweb/ebicsweb', host: 'SIZBN001') }

          before do
            allow_any_instance_of(Epics::Client).to receive(:HAC).and_return(File.read('spec/fixtures/hac_cd1.xml'))
          end

          it 'fetches the HAC statement' do
            described_class.remote_records(account.id)
          end

          it 'returns an array of actions' do
            expect(described_class.remote_records(account.id).map { |a| a[:action] }).to eq(["file_upload", "es_verification", "order_hac_final_pos"])
          end

          it 'extracts reason codes' do
            expect(described_class.remote_records(account.id).map { |a| a[:reason_code] }).to eq(["TS01", "DS01", ""])
          end

          it 'extracts record ids' do
            expect(described_class.remote_records(account.id).map { |a| a[:ids] }).to eq([{"PartnerID"=>"1234560F", "OrderType"=>"CD1", "OrderID"=>"N013", "UserID"=>"12345601", "TimeStamp"=>"2015-04-14T18:12:26.570Z"}, {"PartnerID"=>"1234560F", "OrderType"=>"CD1", "OrderID"=>"N013", "UserID"=>"12345601", "TimeStamp"=>"2015-04-14T18:12:29.310Z"}, {"PartnerID"=>"1234560F", "OrderType"=>"CD1", "OrderID"=>"N013", "UserID"=>"12345601", "TimeStamp"=>"2015-04-14T18:12:29.310Z"}])
          end
        end
      end
    end
  end
end
