# frozen_string_literal: true

require "benchmark"
require "json"
require "faraday"
require "sequel"

require_relative "event"
require_relative "../middleware/signer"
require_relative "../../config/configuration"

module Box
  class WebhookDelivery < Sequel::Model
    many_to_one :event

    def self.deliver(event)
      new(event: event) do |delivery|
        delivery.save
        delivery.deliver
      end
    end

    def deliver
      response, execution_time = execute_request
      set(
        delivered_at: DateTime.now,
        response_body: response.body,
        reponse_headers: Sequel.pg_json(response.headers.stringify_keys),
        response_status: response.status,
        response_time: execution_time
      )
      save
      response.success? ? event.delivery_success! : event.delivery_failure!
    rescue Event::NoCallback => _ex
      Box.logger.warn("[WebhookDelivery] No callback url for event. event_id=#{event.id}")
    end

    def execute_request
      response = nil
      execution_time = 0
      begin
        execution_time = Benchmark.realtime do
          conn = build_connection(event.callback_url)
          response = conn.post do |req|
            req.url URI(event.callback_url).path
            req.headers["Content-Type"] = "application/json"
            payload = event.to_webhook_payload.to_json
            req.body = Box.configuration.encrypt_webhooks? ? encrypt(payload) : payload
          end
        end
      rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Faraday::Error => ex
        Box.logger.warn("[WebhookDelivery] Failed for event_id=#{event.id}: #{ex.message}")
        response = FailedResponse.new(ex.message)
      end
      [response, execution_time]
    end

    def encrypt(payload)
      # AES encryption
      cipher = OpenSSL::Cipher.new("AES-256-CBC")
      aes_key = cipher.random_key
      cipher.encrypt
      cipher.key = aes_key
      iv = cipher.random_iv
      encrypted_payload = cipher.update(payload) + cipher.final

      # Combine IV and encrypted payload
      encoded_iv = Base64.strict_encode64(iv)
      encoded_encrypted_payload = Base64.strict_encode64(encrypted_payload)

      public_key = OpenSSL::PKey::RSA.new(Base64.decode64(Box.configuration.webhook_encryption_key))
      encoded_aes_key = Base64.strict_encode64(aes_key)
      encrypted_encoded_aes_key = public_key.public_encrypt(encoded_aes_key)
      encoded_encrypted_encoded_aes_key = Base64.strict_encode64(encrypted_encoded_aes_key)
      "#{encoded_encrypted_encoded_aes_key}$#{encoded_iv}$#{encoded_encrypted_payload}"
    end

    class FailedResponse
      def initialize(message)
        @message = message
      end

      def success?
        false
      end

      def body
        @message
      end

      def headers
        {}
      end

      def status
        0
      end
    end

    private

    def extract_auth(url)
      url.match(%r{://(.*):(.*)@})&.captures
    end

    def build_connection(callback_url)
      auth = extract_auth(callback_url)
      uri = URI(callback_url)
      Faraday.new("#{uri.scheme}://#{uri.host}") do |conn|
        conn.request :basic_auth, *auth if auth
        conn.request :signer, secret: event.account.organization.webhook_token
        conn.adapter Faraday.default_adapter
      end
    end
  end
end
