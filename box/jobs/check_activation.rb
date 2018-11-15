require_relative '../queue'
require_relative '../models/subscriber'

module Box
  module Jobs
    class CheckActivation
      include Sidekiq::Worker
      sidekiq_options queue: 'check.activations'

      def perform(subscriber_id)
        subscriber = Subscriber.find(id: subscriber_id)
        if subscriber.activate!
          Box.logger.info("[Jobs::CheckActivation] Activated subscriber! subscriber_id=#{subscriber_id}")
        else
          Queue.check_subscriber_activation(subscriber_id, subscriber.account.config.activation_check_interval)
          Box.logger.info("[Jobs::CheckActivation] Failed to activate subscriber! subscriber_id=#{subscriber_id}")
        end
      end
    end
  end
end
