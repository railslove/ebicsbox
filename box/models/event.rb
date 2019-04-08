require 'openssl'
require 'sequel'

require_relative '../queue'
require_relative '../models/account'
require_relative '../models/organization'
require_relative './webhook_delivery'

module Box
  class Event < Sequel::Model
    SUPPORTED_TYPES = [
      :account_created,
      :debit_created,
      :credit_created,
      :statement_created,
      :ebics_user_activated,
      :credit_status_changed,
      :debit_status_changed
    ]

    RETRY_THRESHOLD = 20

    NoCallback = Class.new(StandardError)

    one_to_many :webhook_deliveries
    many_to_one :account

    dataset_module do
      def paginated(page, per_page)
        limit(per_page).offset((page - 1) * per_page)
      end

      def by_organization(organization)
        left_join(:accounts, id: :account_id)
        .where(accounts__organization_id: organization.id)
        .select_all(:events)
      end
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
        account_id: payload[:account_id],
      )
      event.save
      Queue.trigger_webhook(event_id: event.id)
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
        Queue.trigger_webhook({ event_id: id }, { delay: delay_for(webhook_retries) })
      end
      save
    end

    def delay_for(attempt)
      5 * ((attempt - 1) ** 2)
    end

    def to_webhook_payload
      payload.merge(action: type, triggered_at: triggered_at)
    end
  end
end
