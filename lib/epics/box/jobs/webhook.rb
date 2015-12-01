require 'epics/box/models/event'
require 'epics/box/models/webhook_delivery'

module Epics
  module Box
    module Jobs
      class Webhook
        def self.process!(message)
          if event = Event[message[:event_id]]
            delivery = WebhookDelivery.deliver(event)
            Box.logger.info("[Jobs::Webhook] Attempt to deliver a webhook. event_id=#{event.id} delivery_id=#{delivery.id}")
          else
            Box.logger.error("[Jobs::Webhook] Failed to deliver a webhook. No event found. event_id=#{message[:event_id]}")
          end
        end
      end
    end
  end
end
