require "epics/box/models/event"

module Epics
  module Box
    RSpec.describe Event do
      describe 'supported types' do
        described_class::SUPPORTED_TYPES.each do |event|
          before do
            allow(described_class).to receive(:publish)
          end

          it "supports #{event}" do
            expect(described_class).to respond_to(event)
          end

          it "redirects the call to a publish call" do
            described_class.public_send(event, { some: 'payload' })
            expect(described_class).to have_received(:publish).with(event, some: 'payload')
          end
        end
      end

      describe '.publish' do
        it 'persists the event' do
          expect { described_class.publish('some_event', some: 'payload') }.to change { Event.count }.by(1)
        end

        it 'publishes it to the queue'

        it 'logs it to replicated audit log'
      end

      describe ".signature" do
        # Signature for specs is defined in support configuration

        it 'returns a signature for given payload' do
          expect(described_class.signature(some: 'payload')).to eq('sha1=b7842da55ba20279461f961222e3b4b72d21a3d5')
        end

        it 'always generates the same signature with a given payload' do
          signatures = Array.new(5).map { described_class.signature(some: 'payload') }
          expect(signatures.uniq.size).to eq(1)
        end

        it 'generates different signatures for different payloads' do
          sig_1 = described_class.signature(some: 'payload')
          sig_2 = described_class.signature(some: 'other payload')
          expect(sig_1).to_not eq(sig_2)
        end
      end

      describe "default values" do
        subject { described_class.create }

        it "generates a public id" do
          expect(subject.public_id).to match(/\A[\da-f]{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}\z/i)
        end

        it "sets the time when the event was triggered" do
          expect(subject.triggered_at).to be_kind_of(Time)
        end

        it "sets webhook status to pending" do
          expect(subject.webhook_status).to eq('pending')
        end

        it "sets webhook retry count to 0" do
          expect(subject.webhook_retries).to eq(0)
        end
      end
    end
  end
end
