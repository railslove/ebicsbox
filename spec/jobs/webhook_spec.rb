require 'spec_helper'

module Box
  module Jobs
    RSpec.describe Webhook do
      let(:event) { Event.create }

      describe '.process!' do
        before do
          allow(WebhookDelivery).to receive(:deliver).with(instance_of(Event)).and_call_original
        end

        it 'triggers a webhook request for given event' do
          described_class.process!(event_id: event.id)
          expect(WebhookDelivery).to have_received(:deliver).with(instance_of(Event))
        end

        it 'logs an info message with response code' do
          expect { described_class.process!(event_id: event.id) }.to have_logged_message("Attempt to deliver a webhook")
        end
      end
    end
  end
end
