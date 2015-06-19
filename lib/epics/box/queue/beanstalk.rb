require 'beaneater'

Beaneater.configure do |config|
  config.job_parser = lambda { |body| JSON.parse(body, symbolize_names: true) }
end


class Epics::Box::Queue::Beanstalk

  def initialize
    @beanstalk  ||= Beaneater.new(ENV['BEANSTALKD_URL'])
    @logger     ||= Logger.new(STDOUT)
    @db         ||= ::DB
  end

  def publish(queue, payload, options = {})
    @beanstalk.tubes[queue.to_s].put(JSON.dump(payload), options)
  end

  def process!
    @beanstalk.jobs.register('debit') do |job|
      begin
        message = job.body
        pain = Base64.strict_decode64(message[:payload])

        transaction = Epics::Box::Transaction.create(account_id: message[:account_id], type: "debit", payload: pain, eref: message[:eref], status: "created", order_type: Epics::Box::DEBIT_MAPPING[message[:instrument]])

        transaction_id, order_id = transaction.account.client.public_send(transaction.order_type, pain)

        transaction.update(ebics_order_id: order_id, ebics_transaction_id: transaction_id)

        publish("check.orders", {do: :it, account_ids: [message[:account_id]]}, {delay: 120} ) unless @beanstalk.tubes['check.orders'].peek(:delayed)

        @logger.info("debit #{transaction.id}")
      rescue Exception => e
        @logger.error(e.message)
      end
    end

    @beanstalk.jobs.register('credit') do |job|
      message = job.body
      pain = Base64.strict_decode64(message[:payload])

      transaction = Epics::Box::Transaction.create(account_id: message[:account_id], type: "credit", payload: pain, eref: message[:eref], status: "created", order_type: :CCT)

      transaction_id, order_id = transacion.account.client.CCT(pain)

      transaction.update(ebics_order_id: order_id, ebics_transaction_id: transaction_id)

      publish("check.orders", {do: :it, account_ids: [message[:account_id]]}, {delay: 120} ) unless @beanstalk.tubes['check.orders'].peek(:delayed)

      @beanstalk.tubes["orders"].put(transaction_id)
      @logger.info("credit #{transaction_id}")
    end

    @beanstalk.jobs.register('update.statements') do |job|
      Epics::Box::Account.each do |account|
        publish("sta", {do: :it, account_id: account.id})
      end
    end

    @beanstalk.jobs.register('sta') do |job|
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
        @logger.info(e.message)
      rescue Exception => e
        @logger.error(e.message)
      end
    end

    @beanstalk.jobs.register('check.orders') do |job|
      begin
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
      rescue Exception => e
        @logger.error(e.message)
      end
    end

    @beanstalk.jobs.register('web') do |job|
      begin
        message = job.body
        account = Epics::Box::Account[message[:account_id]]
        if account.callback_url
          res = HTTParty.post(account.callback_url, body: message[:payload])
          @logger.info("callback triggered: #{res.code} #{res.parsed_response}")
        else
          @logger.info("no callback configured for #{account.name}")
        end
      rescue Exception => e
        @logger.error(e.message)
      end
    end

    @beanstalk.jobs.process!
  end

end
