module Epics
  module Box
    module Jobs
      class CheckActivation
        def self.process!(message)
          account = Account.find(id: message[:account_id])
          if account.activate!
            Box.logger.info("[Jobs::CheckActivation] Activated account! account_id=#{account.id}")
          else
            Queue.check_account_activation(account.id)
            Box.logger.info("[Jobs::CheckActivation] Failed to activate account! account_id=#{account.id}")
          end
        end
      end
    end
  end
end
