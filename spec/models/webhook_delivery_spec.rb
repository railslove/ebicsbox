# frozen_string_literal: true

require 'faraday'
require 'openssl'
require 'base64'
require 'json'

module Box
  RSpec.describe WebhookDelivery do
    let(:organization) { Fabricate(:organization) }
    let(:account) { Fabricate(:account, organization: organization) }
    let(:event) { Event.create type: 'test', payload: { foo: :bar }, account: account }

    before do
      subject.event = event
      stub_request(:post, 'https://myapp.url/webhooks')
      @request = stub_request(:post, 'http://mycallback.url/')
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

          it 'does encrypt the payload if encrypt_webhooks is true' do
            # Set up Event to return consistent payload
            expected_payload = {"foo": "bar"}
            allow_any_instance_of(Box::Event).to receive(:to_webhook_payload).and_return(expected_payload)

            # Set up public encryption key
            webhook_encryption_public_key_pem = File.read('./spec/webhook_encryption_public_key_RSPEC_ONLY.pem')
            webhook_encryption_public_key_base_64 = Base64.encode64(webhook_encryption_public_key_pem)
            webhook_encryption_public_key = OpenSSL::PKey::RSA.new(webhook_encryption_public_key_pem)

            # Set up private encryption key
            webhook_encryption_private_key_pem = File.read('./spec/webhook_encryption_private_key_RSPEC_ONLY.pem')
            webhook_encryption_private_key = OpenSSL::PKey::RSA.new(webhook_encryption_private_key_pem)
            aes_key = OpenSSL::Cipher.new('AES-256-CBC')

            # Set up configuration
            allow_any_instance_of(Box::Configuration).to receive(:encrypt_webhooks?).and_return(true)
            allow_any_instance_of(Box::Configuration).to receive(:webhook_encryption_key).and_return(webhook_encryption_public_key_base_64)
            allow(OpenSSL::Cipher).to receive(:new).and_return(aes_key)

            expected_payload_encrypted = Base64.encode64(webhook_encryption_public_key.public_encrypt(expected_payload.to_json))

            allow_any_instance_of(Faraday::Request).to receive(:body=) do |instance, payload|
              payload_as_json = JSON.parse(payload)

              decrypted_aes_key = webhook_encryption_private_key.private_decrypt(Base64.decode64(payload_as_json['encrypted_aes_key_base64']))
              encrypted_payload = Base64.decode64(payload_as_json['encrypted_payload_base64'])

              cipher = OpenSSL::Cipher.new('AES-256-CBC')
              cipher.decrypt
              cipher.key = decrypted_aes_key
              decrypted_payload = cipher.update(encrypted_payload) + cipher.final

              expect(decrypted_payload).to eq(expected_payload.to_json)
            end

            subject.execute_request
          end

          it 'does not encrypt payload if encrypt_webhooks is false' do
            # Set up Event to return consistent payload
            expected_payload = {"foo": "bar"}
            allow_any_instance_of(Box::Event).to receive(:to_webhook_payload).and_return(expected_payload)

            # Set up configuration
            allow_any_instance_of(Box::Configuration).to receive(:encrypt_webhooks?).and_return(false)

            allow_any_instance_of(Faraday::Request).to receive(:body=) do |instance, payload|
              expect(payload).to eq(expected_payload.to_json)
            end

            subject.execute_request
          end

        end

        context 'without auth defined' do
          before { allow_any_instance_of(Faraday::Connection).to receive(:basic_auth).with('user', 'pass') }

          it 'does not set anything auth related' do
            expect_any_instance_of(Faraday::Connection).to_not receive(:basic_auth)
            subject.execute_request
          end
        end
      end

      context 'no callback url defined' do
        before { allow_any_instance_of(Account).to receive(:try).with(:callback_url).and_return(nil) }

        it 'raises an exception' do
          expect { subject.execute_request }.to raise_error(Event::NoCallback)
        end
      end

      context 'with auth callback_url defined' do
        before { allow_any_instance_of(Event).to receive(:callback_url).and_return('http://user:pass@mycallback.url') }
        before { allow_any_instance_of(Faraday::Connection).to receive(:basic_auth).with('user', 'pass') }

        it 'sets basic auth information in faraday' do
          expect_any_instance_of(Faraday::Connection).to receive(:basic_auth).with('user', 'pass')
          subject.execute_request
        end
      end
    end

    describe '#deliver' do
      context 'no callback url specified' do
        before do
          allow(subject).to receive(:execute_request).and_raise(Event::NoCallback, 'not configured')
        end

        it 'logs a warning' do
          expect { subject.deliver }.to have_logged_message('No callback url for event.')
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
          expect(subject.reponse_headers).to eq('User-Agent' => 'Spec')
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

    context 'payload signature' do
      it 'signs the request according to its payload' do
        response, _execution_time = subject.execute_request
        hmac = response.env.request_headers['X-Signature']
        expect(hmac.length).to eq(45)
        expect(hmac).to match(/^sha1=.*/)
      end
    end

    describe '#extract_auth' do
      context 'callback url with auth specified' do
        it 'extracts authentication data' do
          url = 'http://user:pass@mycallback.url'
          expect(subject.send(:extract_auth, url)).to eq(%w[user pass])
        end
      end
      context 'callback url without auth specified' do
        it 'returns nil' do
          url = 'http://mycallback.url'
          expect(subject.send(:extract_auth, url)).to eq(nil)
        end
      end
    end
  end
end
