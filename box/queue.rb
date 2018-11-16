require 'sidekiq'
require 'sidekiq/api'
require 'active_support/core_ext/array'

require_relative './jobs/credit'
require_relative './jobs/debit'
require_relative './jobs/fetch_processing_status'
require_relative './jobs/fetch_statements'
require_relative './jobs/webhook'
require_relative './jobs/check_activation'

module Box
  class Queue
    def self.clear!(queue)
      Sidekiq::Queue.new(queue).clear
    end

    def self.update_processing_status(account_ids = nil)
      account_ids ||= Account.all_active_ids

      # do not schedule job if already scheduled
      return if Sidekiq::ScheduledSet.new.any? { |j| j.item['class'] == Jobs::FetchProcessingStatus.name }

      delay = Box.configuration.hac_retrieval_interval.seconds
      Jobs::FetchProcessingStatus.perform_in(delay, account_ids: Array.wrap(account_ids))
    end

    def self.fetch_account_statements(account_ids = nil)
      account_ids ||= Account.all_active_ids
      Jobs::FetchStatements.perform_async(account_ids: Array.wrap(account_ids))
    end

    def self.trigger_webhook(payload, options = {})
      delay = options.fetch(:delay, 0)
      Jobs::Webhook.perform_in(delay, payload)
    end

    def self.execute_credit(payload)
      Jobs::Credit.perform_async(payload)
    end

    def self.execute_debit(payload)
      Jobs::Debit.perform_async(payload)
    end

    def self.check_subscriber_activation(subscriber_id, delay)
      Jobs::CheckActivation.perform_in(delay, subscriber_id: subscriber_id)
    end
  end
end
