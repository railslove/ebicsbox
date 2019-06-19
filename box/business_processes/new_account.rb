require_relative '../models/event'

module Box
  module BusinessProcesses
    class NewAccount
      # Raised when something goes wrong when setting up remote ebics_user
      EbicsError = Class.new(StandardError)

      def self.create!(organization, user, params)
        # Remove it, so we can safely pass params to account create method
        ebics_user = params.delete(:ebics_user)

        # Always create fake accounts in sandbox mode and set activation_check_interval
        # to let the transaction finish
        if Box.configuration.sandbox?
          params[:mode] = 'Fake'
          params[:config] = { activation_check_interval: 3 }
        end

        DB.transaction do
          account = organization.add_account(params)
          ebics_user = EbicsUser.find_or_create(remote_user_id: ebics_user, user_id: user.id)
          account.add_ebics_user(ebics_user) unless ebics_user.in?(account.ebics_users)

          raise EbicsError unless ebics_user.setup!(account)

          Event.account_created(account)
          account
        end
      end
    end
  end
end
