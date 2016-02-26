require 'openssl'

require_relative './webhook_delivery'

module Epics
  module Box
    class Event < Sequel::Model
      SUPPORTED_TYPES = [
        :account_created,
        :debit_created,
        :debit_failed,
        :debit_succeeded,
        :credit_created,
        :credit_failed,
        :credit_suceeded,
        :statement_created,
        :statement_updated,
        :subscriber_activated,
        :transaction_updated,
      ]
      RETRY_THRESHOLD = 10
      DELAY = {
        0 => 0,
        1 => 10,
        2 => 10,
        3 => 10,
        4 => 30,
        5 => 30,
        6 => 30,
        7 => 60,
        8 => 300,
        9 => 600,
      }

      NoCallback = Class.new(StandardError)

      one_to_many :webhook_deliveries
      many_to_one :account

      def_dataset_method(:paginated) do |page, per_page|
        limit(per_page).offset((page - 1) * per_page)
      end

      def_dataset_method(:by_organization) do |organization|
        left_join(:accounts, id: :account_id)
        .where(accounts__organization_id: organization.id)
        .select_all(:events)
      end


      def self.respond_to_missing?(method_name, include_private = false)
        SUPPORTED_TYPES.include?(method_name) || super
      end

      def self.method_missing(method_name, *args, &block)
        if SUPPORTED_TYPES.include?(method_name)
          data = args.shift
          if data.respond_to?(:as_event_payload)
            data = data.as_event_payload
          end
          publish(method_name, *(args.unshift(data)))
        else
          super # ignore and pass along
        end
      end

      def self.publish(event_type, payload = {})
        event = new(
          type: event_type,
          payload: Sequel.pg_json(payload.stringify_keys),
          signature: signature(payload),
          account_id: payload[:account_id],
        )
        event.save
        Queue.trigger_webhook(event_id: event.id)
      end

      def self.signature(payload)
        digest = OpenSSL::Digest.new('sha1')
        secret = Account[payload[:account_id]].organization.webhook_token
        'sha1=' + OpenSSL::HMAC.hexdigest(digest, secret, payload.to_s)
      end

      def callback_url
        account.try(:callback_url) || raise(NoCallback)
      end

      def account
        @account ||= Account[account_id]
      end

      def delivery_success!
        set webhook_status: 'success'
        save
      end

      def delivery_failure!
        set(webhook_retries: webhook_retries.to_i + 1)
        if webhook_retries >= RETRY_THRESHOLD
          set(webhook_status: 'failed')
        else
          Queue.trigger_webhook({ event_id: id }, { delay: DELAY[webhook_retries] })
        end
        save
      end

      def to_webhook_payload
        payload.merge(action: type, triggered_at: triggered_at)
      end
    end
  end
end
