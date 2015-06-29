module Epics
  module Box
    module Jobs
      class Webhook
        def self.process!(message)
          event = Event[message[:event_id]]
          delivery = WebhookDelivery.deliver(event)
          Box.logger.info("[Jobs::Webhook] Attempt to deliver a webhook. event_id=#{event.id} delivery_id=#{delivery.id}")
        end
      end
    end
  end
end
