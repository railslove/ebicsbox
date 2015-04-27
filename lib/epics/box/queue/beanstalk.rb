require 'beaneater'

class Epics::Box::Queue::Beanstalk

  def initialize
    @beanstalk  ||= Beaneater::Pool.new
    @logger     ||= Logger.new(STDOUT)
    @db         ||= ::DB
  end

  def publish(queue, payload, options = {})
    @beanstalk.tubes[queue.to_s].put(JSON.dump(payload), options)
  end

  def process!
    @beanstalk.jobs.register('debit') do |job|
      begin
        message = JSON.parse(job.body, symbolize_names: true)
        pain = Base64.strict_decode64(message[:payload])

        transaction = Epics::Box::Transaction.create(account_id: message[:account_id], type: "debit", payload: pain, eref: message[:eref], status: "created")

        transaction_id, order_id = ["TRX001","N00X"]#transacion.account.client.CD1(pain)

        transaction.update(ebics_order_id: order_id, ebics_transaction_id: transaction_id)

        publish("check.orders", {do: :it, account_ids: [message[:account_id]]}, {delay: 120} ) unless @beanstalk.tubes['check.orders'].peek(:delayed)

        @logger.info("debit #{transaction.id}")
      rescue Exception => e
        @logger.error(e.message)
      end
    end

    @beanstalk.jobs.register('credit') do |job|
      message = JSON.parse(job.body, symbolize_names: true)
      pain = Base64.strict_decode64(message[:payload])

      transaction = Epics::Box::Transaction.create(account_id: message[:account_id], type: "credit", payload: pain, eref: message[:eref], status: "created")

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
        message = JSON.parse(job.body, symbolize_names: true)

        message[:account_ids].each do |account_id|
          account = Epics::Box::Account[account_id]
          @logger.info("STA import for #{account.name}")

          last_import = @db[:imports].where(account_id: account_id).order(:date).last || {date: Date.today}
          to = Date.today

          if last_import[:date] < to
            mt940 = File.read('/Users/kangguru/Downloads/spk.mt940')#account.client.STA("#{(last_import[:date])}" , "#{(to)}")

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
                  Epics::Box::Statement.create(trx)
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
        @logger.error(e.backtrace)
      end
    end

    @beanstalk.jobs.register('check.orders') do |job|
      begin
        message = JSON.parse(job.body, symbolize_names: true)

        message[:account_ids].each do |account_id|
          account = Epics::Box::Account[account_id]
          @logger.debug("reconciling orders by HAC for #{account.name}")
          file = File.open(File.expand_path("~/hac.xml")) # account.client.HAC(Date.today - 1, Date.today) #
          Nokogiri::XML(file).remove_namespaces!.xpath("//OrgnlPmtInfAndSts").each do |info|
            reason_code = info.xpath("./StsRsnInf/Rsn/Cd").text
            action = info.xpath("./OrgnlPmtInfId").text
            ids    = info.xpath("./StsRsnInf/Orgtr/Id/OrgId/Othr").inject({}) {|memo, node| memo[node.at_xpath("./SchmeNm/Prtry").text] = node.at_xpath("./Id").text;memo }

            if ids["OrderID"]
              if trx = Epics::Box::Transaction[ebics_order_id: ids["OrderID"]]
                trx.set_state_from(action.downcase, reason_code)
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
      message = JSON.parse(job.body, symbolize_names: true)
      HTTParty.post(message[:callback], body: Time.now.to_s)
      @logger.info("callback")
    end

    @beanstalk.jobs.process!
  end

end
