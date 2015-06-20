require 'beaneater'

require "epics/box/jobs/debit"
require "epics/box/jobs/credit"

Beaneater.configure do |config|
  config.job_parser = lambda { |body| JSON.parse(body, symbolize_names: true) }
  config.job_serializer  = lambda { |body| JSON.dump(body) }
end

module Epics
  module Box
    class Queue
      ORDER_TUBE = 'check.orders'
      STA_TUBE = 'sta'

      attr_accessor :logger

      def self.client
        @client ||= Beaneater.new(Box.configuration.beanstalkd_url)
      end

      def self.check_accounts(account_ids = nil)
        account_ids ||= Account.all_ids
        unless client.tubes[ORDER_TUBE].peek(:delayed)
          client.tubes[ORDER_TUBE].put({ do: :it, account_ids: Array.wrap(account_ids) }, { delay: Epics::Box.configuration.hac_retrieval_interval })
        end
      end

      def self.check_processing_status(account_ids = nil)
        account_ids ||= Account.all_ids
        client.tubes[STA_TUBE].put(account_ids: Array.wrap(account_ids))
      end


      def initialize
        self.logger ||= Box.logger
        @db ||= ::DB
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
          begin
            message = job.body

            message[:account_ids].each do |account_id|
              account = Epics::Box::Account[account_id]
              @logger.info("STA import for #{account.name}")

              last_import = @db[:imports].where(account_id: account_id).order(:date).last || {date: Date.today}
              to = Date.today

              if last_import[:date] < to
                # mt940 = account.client.STA("#{(last_import[:date])}" , "#{(to)}") # File.read('/Users/kangguru/Downloads/spk.mt940')#
                mt940 = File.read( File.expand_path("~/sta.mt940"))
                @logger.info(@db)

                Cmxl.parse(mt940).each do |s|
                  s.transactions.each do |t|
                    trx = {
                      account_id: account.id,
                      sha: Digest::SHA2.hexdigest(t.information),
                      date: t.date,
                      entry_date: t.entry_date,
                      amount_cents: t.amount_in_cents,
                      sign: t.sign,
                      debit: t.debit?,
                      swift_code: t.swift_code,
                      reference: t.reference,
                      bank_reference: t.bank_reference,
                      bic: t.bic,
                      iban: t.iban,
                      name: t.name,
                      information: t.information,
                      description: t.description,
                      eref: t.sepa["EREF"],
                      mref: t.sepa["MREF"],
                      svwz: t.sepa["SVWZ"],
                      creditor_identifier: t.sepa["CRED"]
                    }

                    if Epics::Box::Statement.where({sha: trx[:sha]}).first
                      @logger.debug("the sha #{t.sha} is already here")
                    else
                      statement = Epics::Box::Statement.create(trx)

                      if transaction = Epics::Box::Transaction.where({eref: statement.eref}).first
                        transaction.add_statement(statement)
                        if statement.credit?
                          transaction.set_state_from("credit_received")
                        elsif statement.debit?
                          transaction.set_state_from("debit_received")
                        end

                        publish("web", account_id: account_id, payload: transaction.to_hash)
                      end
                    end
                  end
                end
              else
                @logger.info("#{last_import[:date]} too likely #{to}")
              end
              @db[:imports].insert(date: to, account_id: account_id)
            end
          rescue Epics::Error::BusinessError => e
            # Expected: Raised if no new statements are available
            @logger.info(e.message)
            job.delete
          rescue Exception => e
            @logger.error(e.message)
          end
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

        self.class.client.jobs.register('web') do |job|
          with_error_logging do
            message = job.body
            account = Epics::Box::Account[message[:account_id]]
            if account.callback_url
              res = HTTParty.post(account.callback_url, body: message[:payload])
              @logger.info("callback triggered: #{res.code} #{res.parsed_response}")
            else
              @logger.info("no callback configured for #{account.name}")
            end
          end
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
