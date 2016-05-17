require 'beaneater'

require_relative './jobs/credit'
require_relative './jobs/debit'
require_relative './jobs/fetch_processing_status'
require_relative './jobs/fetch_statements'
require_relative './jobs/webhook'
require_relative './jobs/check_activation'

Beaneater.configure do |config|
  config.job_parser = lambda { |body| JSON.parse(body, symbolize_names: true) }
  config.job_serializer  = lambda { |body| JSON.dump(body) }
end

module Epics
  module Box
    class Queue
      DEBIT_TUBE = 'debit'
      CREDIT_TUBE = 'credit'
      ORDER_TUBE = 'check.orders'
      STA_TUBE = 'sta'
      WEBHOOK_TUBE = 'web'
      ACTIVATION_TUBE = 'check.activation'

      attr_accessor :logger

      def self.client
        @client ||= Beaneater.new(Box.configuration.beanstalkd_url)
      end

      def self.clear!(queue)
        client.tubes[queue].try(:clear)
      end

      def self.update_processing_status(account_ids = nil)
        account_ids ||= Account.all_active_ids
        unless client.tubes[ORDER_TUBE].peek(:delayed)
          client.tubes[ORDER_TUBE].put({ do: :it, account_ids: Array.wrap(account_ids) }, { delay: Epics::Box.configuration.hac_retrieval_interval })
        end
      end

      def self.fetch_account_statements(account_ids = nil)
        account_ids ||= Account.all_active_ids
        client.tubes[STA_TUBE].put(account_ids: Array.wrap(account_ids))
      end

      def self.trigger_webhook(payload, options = {})
        client.tubes[WEBHOOK_TUBE].put(payload, options)
      end

      def self.execute_credit(payload)
        client.tubes[CREDIT_TUBE].put(payload)
      end

      def self.execute_debit(payload)
        client.tubes[DEBIT_TUBE].put(payload)
      end

      def self.check_subscriber_activation(subscriber_id, delayed = true)
        options = delayed ? { delay: Epics::Box.configuration.activation_check_interval } : {}
        client.tubes[ACTIVATION_TUBE].put({ subscriber_id: subscriber_id }, options)
      end


      def initialize
        self.logger ||= Box.logger
      end

      def publish(queue, payload, options = {})
        self.class.client.tubes[queue.to_s].put(payload, options)
      end

      def process!
        register(DEBIT_TUBE, Jobs::Debit)
        register(CREDIT_TUBE, Jobs::Credit)
        register(ORDER_TUBE, Jobs::FetchProcessingStatus)
        register(STA_TUBE, Jobs::FetchStatements)
        register(WEBHOOK_TUBE, Jobs::Webhook)
        register(ACTIVATION_TUBE, Jobs::CheckActivation)
        DB.extension(:connection_validator)
        DB.pool.connection_validation_timeout = -1
        self.class.client.jobs.process!
      end

      def register(tube_name, klass)
        self.class.client.jobs.register(tube_name) do |job|
          with_error_logging(tube_name, job.id) do
            DB.synchronize { klass.process!(job.body) }
          end
        end
      end

      # Run any job within a block provided to this method to ensure that jobs are not only
      # burried, but also an error is logged. Otherwise, the queue would just swallow any exceptions
      def with_error_logging(tube_name, job_id, &block)
        block.call
      rescue => e
        @logger.error("[Queue] Failed job. tube=#{tube_name} job='#{job_id}' message='#{e.message}'")
        raise
      end

    end
  end
end
