require_relative '../queue'
require_relative '../models/ebics_user'

module Box
  module Jobs
    class CheckActivation
      include Sidekiq::Worker
      sidekiq_options queue: 'check.activations'

      def perform(ebics_user_id)
        ebics_user = EbicsUser.find(id: ebics_user_id)
        if ebics_user.activate!
          Box.logger.info("[Jobs::CheckActivation] Activated ebics_user! ebics_user_id=#{ebics_user_id}")
        else
          Queue.check_ebics_user_activation(ebics_user_id, ebics_user.account.config.activation_check_interval)
          Box.logger.info("[Jobs::CheckActivation] Failed to activate ebics_user! ebics_user_id=#{ebics_user_id}")
        end
      end
    end
  end
end
