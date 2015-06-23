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


      def initialize
        self.logger ||= Box.logger
      end

      def publish(queue, payload, options = {})
        self.class.client.tubes[queue.to_s].put(payload, options)
      end

      def process!
        self.class.client.jobs.register('debit') do |job|
          with_error_logging { Jobs::Debit.process!(job.body) }
        end

        self.class.client.jobs.register('credit') do |job|
          with_error_logging { Jobs::Credit.process!(job.body) }
        end

        self.class.client.jobs.register('sta') do |job|
          with_error_logging { Jobs::FetchStatements.process!(job.body) }
        end

        self.class.client.jobs.register('check.orders') do |job|
          with_error_logging { Jobs::FetchProcessingStatus.process!(job.body) }
        end

        self.class.client.jobs.register('sta') do |job|
          with_error_logging { Jobs::Webhook.process!(job.body) }
        end

        self.class.client.jobs.process!
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
