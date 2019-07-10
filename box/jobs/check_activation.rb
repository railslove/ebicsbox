require_relative '../queue'
require_relative '../models/ebics_user'

module Box
  module Jobs
    class CheckActivation
      include Sidekiq::Worker
      sidekiq_options queue: 'check.activations', retry: false

      def perform
        ebics_users = EbicsUser.where(activated_at: nil).exclude(ini_letter: nil)
        ebics_users.each do |user|
          activate_ebics_user(user)
        end
      end

      private

      def activate_ebics_user(ebics_user)
        if ebics_user.activate!
          Box.logger.info("[Jobs::CheckActivation] Activated ebics_user! ebics_user_id=#{ebics_user.id}")
        else
          Box.logger.info("[Jobs::CheckActivation] Failed to activate ebics_user! ebics_user_id=#{ebics_user.id}")
        end
      end
    end
  end
end
