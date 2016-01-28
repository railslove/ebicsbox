module Box
  RSpec.describe WebhookDelivery do
    let(:event) { Event.create type: 'test' }

    before do
      subject.event = event
      @request = stub_request(:post, "http://mycallback.url/")
    end

    describe '.deliver' do
      it 'creates a new delivery for given event' do
        expect { described_class.deliver(event) }.to change { described_class.count }.by(1)
      end

      it 'triggers delivery of webhook' do
        expect_any_instance_of(described_class).to receive(:deliver)
        described_class.deliver(event)
      end
    end

    describe '#execute_request' do
      context 'with callback_url defined' do
        before { allow_any_instance_of(Event).to receive(:callback_url).and_return('http://mycallback.url') }

        context 'failed request' do
          before { @request.to_timeout }

          it 'still returns a response and timing data' do
            expect(subject.execute_request).to match([an_instance_of(WebhookDelivery::FailedResponse), 0])
          end
        end

        context 'successful request' do
          it 'returns a response' do
            expect(subject.execute_request.size).to eq(2)
          end
        end
      end

      context 'no callback url defined' do
        it 'raises an exception' do
          expect { subject.execute_request }.to raise_error(Event::NoCallback)
        end
      end
    end

    describe '#deliver' do
      context 'no callback url specified' do
        before do
          allow(subject).to receive(:execute_request).and_raise(Event::NoCallback, 'not configured')
        end

        it 'logs a warning' do
          expect { subject.deliver }.to have_logged_message("No callback url for event.")
        end
      end

      context 'with callback_url defined' do
        let(:response) { double('Response', body: 'my test', status: 201, headers: { 'User-Agent' => 'Spec' }, success?: true) }

        before do
          allow(subject).to receive(:execute_request).and_return([response, 1])
        end

        it 'stores response_body' do
          subject.deliver
          expect(subject.response_body).to eq('my test')
        end

        it 'stores response_status' do
          subject.deliver
          expect(subject.response_status).to eq(201)
        end

        it 'stores response_headers' do
          subject.deliver
          expect(subject.reponse_headers).to eq({ 'User-Agent' => 'Spec' })
        end

        it 'stores response_time' do
          subject.deliver
          expect(subject.response_time).to eq(1)
        end

        context 'successful request' do
          it 'triggers success on event' do
            expect_any_instance_of(Event).to receive(:delivery_success!)
            subject.deliver
          end
        end

        context 'failed request' do
          before { allow(response).to receive(:success?).and_return(false) }

          it 'triggers failure on event' do
            expect_any_instance_of(Event).to receive(:delivery_failure!)
            subject.deliver
          end
        end
      end
    end
  end
end
