require 'beaneater'

require 'epics/box/jobs/credit'
require 'epics/box/jobs/debit'
require 'epics/box/jobs/fetch_processing_status'
require 'epics/box/jobs/fetch_statements'
require 'epics/box/jobs/webhook'

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

      attr_accessor :logger

      def self.client
        @client ||= Beaneater.new(Box.configuration.beanstalkd_url)
      end

      def self.update_processing_status(account_ids = nil)
        account_ids ||= Account.all_ids
        unless client.tubes[ORDER_TUBE].peek(:delayed)
          client.tubes[ORDER_TUBE].put({ do: :it, account_ids: Array.wrap(account_ids) }, { delay: Epics::Box.configuration.hac_retrieval_interval })
        end
      end

      def self.fetch_account_statements(account_ids = nil)
        account_ids ||= Account.all_ids
        client.tubes[STA_TUBE].put(account_ids: Array.wrap(account_ids))
      end

      def self.trigger_webhook(payload)
        client.tubes[WEBHOOK_TUBE].put(payload)
      end

      def self.execute_credit(payload)
        client.tubes[CREDIT_TUBE].put(payload)
      end

      def self.execute_debit(payload)
        client.tubes[DEBIT_TUBE].put(payload)
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
        self.class.client.jobs.process!
      end

      def register(tube_name, klass)
        self.class.client.jobs.register(tube_name) do |job|
          with_error_logging do
            DB.synchronize { klass.process!(job.body) }
          end
        end
      end

      # Run any job within a block provided to this method to ensure that jobs are not only
      # burried, but also an error is logged. Otherwise, the queue would just swallow any exceptions
      def with_error_logging(&block)
        block.call
      rescue => e
        @logger.error("[Queue] Failed job. message='#{e.message}'")
        raise
      end

    end
  end
end
