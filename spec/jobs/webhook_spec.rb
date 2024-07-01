# frozen_string_literal: true

require "spec_helper"

module Box
  module Jobs
    RSpec.describe Webhook do
      subject(:job) { described_class.new }
      let(:event) { Event.create }

      describe "#perform" do
        before do
          allow(WebhookDelivery).to receive(:deliver).with(instance_of(Event)).and_call_original
        end

        it "triggers a webhook request for given event" do
          job.perform(event.id)
          expect(WebhookDelivery).to have_received(:deliver).with(instance_of(Event))
        end

        it "logs an info message with response code" do
          expect { job.perform(event.id) }.to have_logged_message("Attempt to deliver a webhook")
        end
      end
    end
  end
end
