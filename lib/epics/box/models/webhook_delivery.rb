require 'benchmark'

module Epics
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
          response_time: execution_time,
        )
        save
        response.success? ? event.delivery_success! : event.delivery_failure!
      rescue Event::NoCallback => ex
        Box.logger.warn("[WebhookDelivery] No callback url for event. event_id=#{event.id}")
      end

      def execute_request
        response = nil
        execution_time = 0
        begin
          execution_time = Benchmark.realtime do
            response = Faraday.post(event.callback_url) do |req|
              req.headers['Content-Type'] = 'application/json'
              req.headers['X-Signature'] = event.signature if event.signature
              req.body = event.to_webhook_payload.to_json
            end
          end
        rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Faraday::Error => ex
          Box.logger.warn("[WebhookDelivery] Failed for event_id=#{event.id}: #{ex.message}")
          response = FailedResponse.new(ex.message)
        end
        [response, execution_time]
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
    end
  end
end
