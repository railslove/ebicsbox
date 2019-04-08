require 'spec_helper'

module Box
  RSpec.describe Apis::V2::Webhooks do
    include_context 'valid user'
    include_context 'with account'

    let!(:successful_event) do
      account.add_event(type: 'control', webhook_status: 'success',
                        webhook_retries: 5)
    end
    let!(:pending_event) do
      account.add_event(type: 'test', webhook_status: 'pending',
                        webhook_retries: 15)
    end
    let!(:failed_event) do
      account.add_event(type: 'test', webhook_status: 'failed',
                        webhook_retries: 20)
    end

    describe 'POST /webhooks/reset' do
      context "without valid access_token" do
        it 'returns a 401' do
          post 'webhooks/reset', {}, TestHelpers::INVALID_TOKEN_HEADER
          expect_status 401
        end
      end

      context "with valid access_token" do
        it 'returns an OK status' do
          post "webhooks/reset", {}, TestHelpers::VALID_HEADERS

          expect_status 201
        end

        it 'returns a list of events' do
          post "webhooks/reset", {}, TestHelpers::VALID_HEADERS
          expect_json_types :array
        end

        it 'does not return successful events' do
          post "webhooks/reset", {}, TestHelpers::VALID_HEADERS

          expect_json '*.type', 'test'
          expect_json_sizes '', 2
        end

        it 'changes the status to pending and retries to 0' do
          post "webhooks/reset", {}, TestHelpers::VALID_HEADERS

          expect(pending_event.refresh.webhook_status).to eq('pending')
          expect(pending_event.refresh.webhook_retries).to eq(0)
          expect(failed_event.refresh.webhook_status).to eq('pending')
          expect(failed_event.refresh.webhook_retries).to eq(0)
        end
      end
    end
  end
end
