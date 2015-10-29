require 'epics/box/presenters/account_presenter'

module Epics
  module Box
    class Delivery < Grape::Entity
      expose :delivered_at
      expose :response_body
      expose :reponse_headers
      expose :response_status
      expose :response_time
    end

    class EventDetailsPresenter < Grape::Entity
      expose :id
      expose :account, using: AccountPresenter
      expose :type
      expose :public_id
      expose :payload
      expose :triggered_at
      expose :signature
      expose :webhook_status
      expose :webhook_retries
      expose :webhook_deliveries, using: Delivery
      expose :webhook_url

      def account
        @account ||= Account[object[:account_id]]
      end

      def webhook_deliveries
        object.webhook_deliveries
      end

      def webhook_url
        account.callback_url
      end
    end
  end
end
