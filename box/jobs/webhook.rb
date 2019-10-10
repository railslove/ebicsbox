# frozen_string_literal: true

require_relative '../models/event'
require_relative '../models/webhook_delivery'

module Box
  module Jobs
    class Webhook
      include Sidekiq::Worker
      sidekiq_options queue: 'webhooks'

      def perform(event_id)
        event = Event.find(id: event_id)
        if event
          delivery = WebhookDelivery.deliver(event)
          Box.logger.info("[Jobs::Webhook] Attempt to deliver a webhook. event_id=#{event.id} delivery_id=#{delivery.id}")
        else
          Box.logger.error("[Jobs::Webhook] Failed to deliver a webhook. No event found. event_id=#{event_id}")
        end
      end
    end
  end
end
