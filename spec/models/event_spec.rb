module Box
  RSpec.describe Event do
    before do
      allow(Queue).to receive(:trigger_webhook)
      allow(Account).to receive(:[]).and_return(double('account', organization: double('orga', webhook_token: 'token')))
    end

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

      it 'publishes it to the queue' do
        described_class.publish('some_event', some: 'payload')
        expect(Queue).to have_received(:trigger_webhook).with(event_id: anything)
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

    describe 'delivery_success!' do
      it 'sets status to success' do
        expect { subject.delivery_success! }.to change { subject.webhook_status }.to('success')
      end
    end

    describe 'delivery_failure!' do
      context 'below retry threshold' do
        before { subject.webhook_retries = 3 }

        it 'increases retry counter by one' do
          expect { subject.delivery_failure! }.to change { subject.webhook_retries }.by(1)
        end

        it 'does not change status' do
          subject.delivery_failure!
          expect(subject.webhook_status).to eq('pending')
        end

        it 'schedules a delayed retry' do
          expect(Queue).to receive(:trigger_webhook).with({ event_id: subject.id }, { delay: subject.delay_for(4) })
          subject.delivery_failure!
        end
      end

      context 'above retry threshold' do
        before { subject.webhook_retries = Box::Event::RETRY_THRESHOLD }

        it 'sets status to failed' do
          expect { subject.delivery_failure! }.to change { subject.webhook_status }.to('failed')
        end
      end
    end

    describe 'reset_webhook_delivery' do
      before { subject.set(webhook_status: 'failed', webhook_retries: 20).save }

      it 'sets the status to "pending"' do
        expect { subject.reset_webhook_delivery }.to change { subject.webhook_status }.to('pending')
      end

      it 'sets the retry count to 0' do
        expect { subject.reset_webhook_delivery }.to change { subject.webhook_retries }.to(0)
      end

      it 'adds the webhook to the event queue' do
        expect(Queue).to receive(:trigger_webhook).with({ event_id: subject.id })

        subject.reset_webhook_delivery
      end
    end
  end
end
