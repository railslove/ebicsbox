module Epics
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
        def self.fetch_new_statements(account_id)
          Box.logger.info("[Jobs::FetchStatements] Starting import. id=#{account_id}")

          account = Account[account_id]

          from_date = account.last_imported_at || (Date.today - 30)
          to_date = Date.today

          if from_date < to_date
            mt940 = account.client.STA(from_date , to_date)
            Cmxl.parse(mt940).map(&:transactions).flatten.each do |transaction|
              create_statement(account_id, transaction)
            end
            account.imported_at!(to_date)
          end
        rescue Epics::Error::BusinessError => ex
          Box.logger.info(ex.message) # expected
        end

        def self.create_statement(account_id, data)
          trx = {
            account_id: account_id,
            sha: Digest::SHA2.hexdigest(data.information),
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
            creditor_identifier: data.sepa["CRED"]
          }

          if statement = Statement.where(sha: trx[:sha]).first
            Box.logger.debug("[Jobs::FetchStatements] Already imported. sha='#{statement.sha}'")
          else
            statement = Statement.create(trx)
            link_statement_to_transaction(account_id, statement)
          end
        end

        def self.link_statement_to_transaction(account_id, statement)
          if transaction = Epics::Box::Transaction.where(eref: statement.eref).first
            transaction.add_statement(statement)

            if statement.credit?
              transaction.set_state_from("credit_received")
            elsif statement.debit?
              transaction.set_state_from("debit_received")
            end

            Event.statement_created(statement.to_webhook_payload)
          end
        end

      end
    end
  end
end
