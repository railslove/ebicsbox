# frozen_string_literal: true

require 'benchmark'
require 'json'
require 'faraday'
require 'sequel'

require_relative './event'
require_relative '../middleware/signer'
require_relative '../../config/configuration'

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
            req.headers['Content-Type'] = 'application/json'
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
      public_key = OpenSSL::PKey::RSA.new(Base64.decode64(Box.configuration.webhook_encryption_key))
      Base64.encode64(public_key.public_encrypt(payload))
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
      url.match(/:\/\/(.*):(.*)@/).try(:captures)
    end

    def build_connection(callback_url)
      auth = extract_auth(callback_url)
      uri = URI(callback_url)
      Faraday.new("#{uri.scheme}://#{uri.host}") do |c|
        c.basic_auth(*auth) if auth
        c.request :signer, secret: event.account.organization.webhook_token
        c.adapter Faraday.default_adapter
      end
    end
  end
end
