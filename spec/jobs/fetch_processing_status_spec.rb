# frozen_string_literal: true

require 'spec_helper'
require 'json'

module Box
  module Jobs
    RSpec.describe FetchProcessingStatus do
      subject(:job) { described_class.new }

      describe '#perform' do
        it 'triggers transaction updates for all records from remote documents' do
          expect(job).to receive(:remote_records).with(1).and_return([{ some: 'data' }])
          expect(job).to receive(:update_transaction).with(1, some: 'data')
          job.perform(1)
        end
      end

      describe '.update_transaction' do
        ACCOUNT_ID = 1

        def do_action(order_id = '0001')
          job.update_transaction(ACCOUNT_ID, action: 'file_upload', reason_code: 'none', ids: { 'OrderID' => order_id })
        end

        context 'transaction with order exists' do
          let!(:old_transaction) { Transaction.create(account_id: ACCOUNT_ID, ebics_order_id: '0001', status: 'created', type: 'debit') }
          let!(:new_transaction) { Transaction.create(account_id: ACCOUNT_ID, ebics_order_id: '0001', status: 'created', type: 'debit') }

          it 'updates the last transaction with that order_id' do
            expect { do_action }.to change { new_transaction.reload.status }.to('file_upload')
          end
        end

        context 'no transaction with order id found' do
          it 'logs an info message' do
            expect { do_action('0002') }.to have_logged_message('[Jobs::FetchProcessingStatus] Transaction not found. account_id=1 order_id=0002')
          end
        end
      end

      describe '.remote_records' do
        let(:keys) { JSON.parse(File.read('spec/fixtures/account.key')) }
        let!(:account) { Account.create(partner: 'EBICS', url: 'https://194.180.18.30/ebicsweb/ebicsweb', host: 'SIZBN001') }
        let!(:ebics_user) { account.add_ebics_user(encryption_keys: JSON.dump(keys), remote_user_id: 'EBIX', signature_class: 'T', activated_at: 1.day.ago) }

        before do
          allow_any_instance_of(Box.configuration.ebics_client).to receive(:HAC).and_return(File.read('spec/fixtures/hac_cd1.xml'))
        end

        it 'fetches the HAC statement' do
          job.remote_records(account.id)
        end

        it 'returns an array of actions' do
          expect(job.remote_records(account.id).map { |a| a[:action] }).to eq(%w[file_upload es_verification order_hac_final_pos])
        end

        it 'extracts reason codes' do
          expect(job.remote_records(account.id).map { |a| a[:reason_code] }).to eq(['TS01', 'DS01', ''])
        end

        it 'extracts record ids' do
          expect(job.remote_records(account.id).map { |a| a[:ids] }).to eq([{ 'PartnerID' => '1234560F', 'OrderType' => 'CD1', 'OrderID' => 'N013', 'UserID' => '12345601', 'TimeStamp' => '2015-04-14T18:12:26.570Z' }, { 'PartnerID' => '1234560F', 'OrderType' => 'CD1', 'OrderID' => 'N013', 'UserID' => '12345601', 'TimeStamp' => '2015-04-14T18:12:29.310Z' }, { 'PartnerID' => '1234560F', 'OrderType' => 'CD1', 'OrderID' => 'N013', 'UserID' => '12345601', 'TimeStamp' => '2015-04-14T18:12:29.310Z' }])
        end
      end
    end
  end
end
