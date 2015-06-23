module Epics
  module Box
    module Jobs
      RSpec.describe Webhook do
        let(:account) { Account.create name: 'Testaccount' }

        describe '.process!' do
          context 'webhook url configured for account' do
            before do
              account.update callback_url: 'http://localhost/test_me'
              @webhook_request = stub_request(:any, "http://localhost/test_me").to_return(status: 200, body: 'ok')
            end

            it 'triggers a webhook request with provided payload' do
              payload = 'Some data'
              described_class.process!(account_id: account.id, payload: payload)
              expect(@webhook_request.with(body: payload)).to have_been_requested
            end

            it 'logs an info message with response code' do
              expect(Box.logger).to receive(:info).with("[Jobs::Webhook] Callback triggered: 200 ok account_id=#{account.id}")
              described_class.process!(account_id: account.id)
            end
          end

          context 'no webhook url configured' do
            before { account.update callback_url: nil }

            it 'logs an info message about missing url' do
              expect(Box.logger).to receive(:info).with("[Jobs::Webhook] No callback configured for Testaccount. account_id=#{account.id}")
              described_class.process!(account_id: account.id)
            end
          end
        end
      end
    end
  end
end
