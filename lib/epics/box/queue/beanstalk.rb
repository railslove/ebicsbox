require 'beaneater'

class Epics::Box::Queue::Beanstalk

  def initialize
    @beanstalk  ||= Beaneater::Pool.new
    @logger     ||= Logger.new(STDOUT)
    @db         ||= ::DB
    @client     ||= Epics::Box::CLIENT
  end

  def publish(queue, payload, options = {})
    @beanstalk.tubes[queue.to_s].put(JSON.dump(payload), options)
  end

  def process!
    @beanstalk.jobs.register('debit') do |job|
      begin
        message = JSON.parse(job.body, symbolize_names: true)
        pain = Base64.strict_decode64(message[:payload])

        transaction = Epics::Box::Transaction.create(type: "debit", payload: pain, eref: message[:eref], status: "created")

        transaction_id, order_id = @client.CD1(pain)

        transaction.update(ebics_order_id: order_id, ebics_transaction_id: transaction_id)

        publish("check.orders", {do: :it}, {delay: 120} ) unless @beanstalk.tubes['check.orders'].peek(:delayed)

        @logger.info("debit #{transaction.id}")
      rescue Exception => e
        @logger.error(e.message)
      end
    end

    @beanstalk.jobs.register('credit') do |job|
      message = JSON.parse(job.body, symbolize_names: true)
      pain = Base64.strict_decode64(message[:payload])

      transaction = Epics::Box::Transaction.create(type: "credit", payload: pain, eref: message[:eref], status: "created")

      transaction_id, order_id = @client.CCT(pain)

      transaction.update(ebics_order_id: order_id, ebics_transaction_id: transaction_id)

      publish("check.orders", {do: :it}, {delay: 120} ) unless @beanstalk.tubes['check.orders'].peek(:delayed)

      @beanstalk.tubes["orders"].put(transaction_id)
      @logger.info("credit #{transaction_id}")
    end

    @beanstalk.jobs.register('sta') do |job|
      begin
        last_import = @db[:imports].order(:date).last || {date: Date.today}
        to = Date.today
        statements = @db[:statements]

        if last_import[:date] < to
          mt940 = @client.STA("#{(last_import[:date])}" , "#{(to)}")

          @logger.info(@db)

          Cmxl.parse(mt940).each do |s|
            s.transactions.each do |t|
              trx = {
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

              if @db[:statements].where(sha: trx[:sha]).count == 0
                statements.insert(trx)
              else
                @logger.debug("the sha #{t.sha} is already here")
              end
            end
          end
        else
          @logger.info("#{last_import[:date]} too likely #{to}")
        end
        @db[:imports].insert(date: to)
      rescue Epics::Error::BusinessError => e
        @logger.info(e.message)
      rescue Exception => e
        @logger.error(e.message)
      end
    end

    @beanstalk.jobs.register('check.orders') do |job|
      begin

        @logger.debug("reconciling orders by HAC")
        file = @client.HAC(Date.today - 1, Date.today) #File.open(File.expand_path("~/hac.xml"))
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
