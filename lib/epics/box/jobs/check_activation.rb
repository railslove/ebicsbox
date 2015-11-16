module Epics
  module Box
    module Jobs
      class CheckActivation
        def self.process!(message)
          subscriber = Subscriber.find(id: message[:subscriber_id])
          if subscriber.activate!
            Box.logger.info("[Jobs::CheckActivation] Activated subscriber! subscriber_id=#{subscriber.id}")
          else
            Queue.check_subscriber_activation(subscriber.id)
            Box.logger.info("[Jobs::CheckActivation] Failed to activate subscriber! subscriber_id=#{subscriber.id}")
          end
        end
      end
    end
  end
end
