require_relative '../models/event'

module Box
  module BusinessProcesses
    class NewAccount
      # Raised when something goes wrong when setting up remote ebics_user
      EbicsError = Class.new(StandardError)

      def self.create!(organization, user, params)
        # Remove it, so we can safely pass params to account create method
        ebics_user = params.delete(:ebics_user)

        # Always create fake accounts in sandbox mode
        if Box.configuration.sandbox?
          params[:mode] = "Fake"
          params[:config] = { activation_check_interval: 3 } # to let the transaction finish
        end

        DB.transaction do
          account = organization.add_account(params)
          ebics_user = account.add_ebics_user(user_id: user.id, remote_user_id: ebics_user)

          if ebics_user.setup!
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
