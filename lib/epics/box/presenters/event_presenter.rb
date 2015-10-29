require 'epics/box/presenters/account_presenter'

module Epics
  module Box
    class Epics::Box::EventPresenter < Grape::Entity
      expose :id
      expose :account, using: AccountPresenter
      expose :type
      expose :public_id
      expose :payload
      expose :triggered_at
      expose :signature
      expose :webhook_status
      expose :webhook_retries

      def account
        Account[object[:account_id]]
      end
    end
  end
end
