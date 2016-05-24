require_relative '../models/event'

module Box
  module BusinessProcesses
    class NewAccount
      # Raised when something goes wrong when setting up remote subscriber
      EbicsError = Class.new(StandardError)

      def self.create!(organization, user, params)
        # Remove it, so we can safely pass params to account create method
        subscriber = params.delete(:subscriber)

        DB.transaction do
          account = organization.add_account(params)
          subscriber = account.add_subscriber(user_id: user.id, remote_user_id: subscriber)

          if subscriber.setup!
            Event.account_created(account)
            account
          else
            raise EbicsError
          end
        end
      end
    end
  end
end
