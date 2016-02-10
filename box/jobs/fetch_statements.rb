module Box
  module Jobs
    class FetchStatements
      def self.process!(message)
        message[:account_ids].each do |account_id|
          fetch_new_statements(account_id)
        end
      end

      # Fetch all new statements for a single account since its last import. Each account import
      # can fail and should not affect imports for other accounts. The BusinessError can occur
      # when no new statements are available
      def self.fetch_new_statements(account_id, from = 30.days.ago.to_date.to_s, to = Date.today.to_s)
        Box.logger.info("[Jobs::FetchStatements] Starting import. id=#{account_id}")

        account = Account.first!(id: account_id)
        mt940 = account.transport_client.STA(from, to)
        statements = Cmxl.parse(mt940)
        statements = statements.delete_if { |sta| !account.iban.end_with?(sta.account_identification.account_number) }
        transactions = statements.map(&:transactions).flatten
        imported = transactions.map { |transaction| create_statement(account_id, transaction, mt940) }

        update_meta_data(account, statements, to)

        { fetched: transactions.count, imported: imported.select{ |obj| obj }.count }
      rescue Sequel::NoMatchingRow => ex
        Box.logger.error("[Jobs::FetchStatements] Could not find account. account_id=#{account_id}")
      rescue Epics::Error::BusinessError => ex
        Box.logger.error(ex.message) # expected
      end

      def self.update_meta_data(account, statements, to)
        return unless statements.any?
        balance = statements.last.closing_balance

        # Update account balance if new data is available
        if !account.balance_date || account.balance_date <= balance.date
          account.set_balance(balance.date, balance.amount_in_cents)
        end

        # Update imported at timestamp
        imported_at = account.last_imported_at

        if !imported_at || imported_at <= Date.parse(to)
          account.imported_at!(Time.now)
        end
      end

      def self.create_statement(account_id, data, raw_data)
        trx = {
          account_id: account_id,
          sha: Digest::SHA2.hexdigest([data.sha, data.date, data.amount_in_cents, data.sepa].join).to_s,
          date: data.date,
          entry_date: data.entry_date,
          amount: data.amount_in_cents,
          sign: data.sign,
          debit: data.debit?,
          swift_code: data.swift_code,
          reference: data.reference,
          bank_reference: data.bank_reference,
          bic: data.bic,
          iban: data.iban,
          name: data.name,
          information: data.information,
          description: data.description,
          eref: data.sepa["EREF"],
          mref: data.sepa["MREF"],
          svwz: data.sepa["SVWZ"],
          creditor_identifier: data.sepa["CRED"],
          raw_data: raw_data,
        }

        if statement = Statement.where(sha: trx[:sha]).first
          Box.logger.debug("[Jobs::FetchStatements] Already imported. sha='#{statement.sha}'")
          false
        else
          statement = Statement.create(trx)
          Event.statement_created(statement)
          link_statement_to_transaction(account_id, statement)
          true
        end
      end

      def self.link_statement_to_transaction(account_id, statement)
        if transaction = Box::Transaction.where(eref: statement.eref).first
          transaction.add_statement(statement)

          if statement.credit?
            transaction.set_state_from("credit_received")
          elsif statement.debit?
            transaction.set_state_from("debit_received")
          end
        end
      end

    end
  end
end
