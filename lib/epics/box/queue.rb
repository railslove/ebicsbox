require 'beaneater'

require "epics/box/jobs/debit"
require "epics/box/jobs/credit"
require "epics/box/jobs/fetch_statements"
require "epics/box/jobs/webhook"

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
          with_error_logging do
            message = job.body
            @logger.debug("check orders")

            message[:account_ids].each do |account_id|
              account = Epics::Box::Account[account_id]
              @logger.debug("reconciling orders by HAC for #{account.name}")

              file = account.client.HAC(Date.today - 1, Date.today)
              Nokogiri::XML(file).remove_namespaces!.xpath("//OrgnlPmtInfAndSts").each do |info|
                reason_code = info.xpath("./StsRsnInf/Rsn/Cd").text
                action = info.xpath("./OrgnlPmtInfId").text
                ids    = info.xpath("./StsRsnInf/Orgtr/Id/OrgId/Othr").inject({}) {|memo, node| memo[node.at_xpath("./SchmeNm/Prtry").text] = node.at_xpath("./Id").text;memo }

                if ids["OrderID"]
                  if trx = Epics::Box::Transaction[ebics_order_id: ids["OrderID"]]
                    status = trx.status
                    if status != trx.set_state_from(action.downcase, reason_code)
                      @logger.debug("#{status} -> #{trx.status}")
                      publish("web", account_id: account_id, payload: trx.to_hash)
                    end
                    @logger.info("#{trx.pk} - #{action} for #{ids["OrderID"]} with #{reason_code}")
                  end
                else
                  @logger.debug("#{action} for #{ids} with reason: #{reason_code}")
                end
              end
            end
          end
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
