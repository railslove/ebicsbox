require 'cmxl'
require 'camt_parser'

require_relative '../models/account'
require_relative '../models/bank_statement'
require_relative '../models/event'

module Box
  module BusinessProcesses
    class ImportStatements
      PARSERS = { 'mt940' => Cmxl, 'camt53' => CamtParser::Format053::Statement }

      def self.parse_bank_statement(bank_statement)
        parser = PARSERS.fetch(bank_statement.account.statements_format, Cmxl)
        result = parser.parse(bank_statement.content)
        result.kind_of?(Array) ? result.first.transactions : result.transactions
      end

      def self.from_bank_statement(bank_statement)
        bank_transactions = self.parse_bank_statement(bank_statement)

        # We need to pass down index and bank statement sequence to create better checksums
        statements = bank_transactions.map do |bank_transaction|
          create_statement(bank_statement, bank_transaction)
        end

        stats = { total: bank_transactions.count, imported: statements.select(&:present?).count }
        Box.logger.info { "[BusinessProcesses::ImportStatements] Imported statements from bank statement. total=#{stats[:total]} imported=#{stats[:imported]}" }
        stats
      end


      def self.create_statement(bank_statement, bank_transaction)
        account = bank_statement.account
        trx = statement_attributes_from_bank_transaction(bank_transaction, bank_statement)

        if (statement = account.statements_dataset.where(sha: trx[:sha]).first)
          Box.logger.info("[BusinessProcesses::ImportStatements] Already imported. sha='#{statement.sha}'")
          false
        else
          statement = account.add_statement(trx.merge(bank_statement_id: bank_statement.id))
          Event.statement_created(statement)
          link_statement_to_transaction(account, statement)
          true
        end
      end

      def self.link_statement_to_transaction(account, statement)
        # find transactions via EREF
        transaction   = account.transactions_dataset.where(eref: statement.eref).first
        # fallback to finding via statement information
        transaction ||= account.transactions_dataset.exclude(currency: 'EUR', status: ['credit_received', 'debit_received']).where{ created_at > 14.days.ago}.detect{|t| statement.information =~ /#{t.eref}/i }

        if transaction
          transaction.add_statement(statement)
          if statement.credit?
            transaction.update_status("credit_received")
          elsif statement.debit?
            transaction.update_status("debit_received")
          end
        end
      end

      def self.checksum(transaction, bank_statement)
        eref = transaction.respond_to?(:eref) ? transaction.eref : transaction.sepa['EREF']
        mref = transaction.respond_to?(:mref) ? transaction.mref : transaction.sepa['MREF']

        payload = [
          bank_statement.remote_account,
          transaction.date,
          transaction.amount_in_cents,
          transaction.iban,
          transaction.name,
          transaction.sign,
          eref,
          mref
        ]
        Digest::SHA2.hexdigest(payload.flatten.compact.join).to_s
      end

      def self.statement_attributes_from_bank_transaction(transaction, bank_statement)
        {
          sha: checksum(transaction, bank_statement),
          date: transaction.date,
          entry_date: transaction.entry_date,
          amount: transaction.amount_in_cents,
          sign: transaction.sign,
          debit: transaction.debit?,
          swift_code: transaction.swift_code,
          reference: transaction.reference,
          bank_reference: transaction.bank_reference,
          bic: transaction.bic,
          iban: transaction.iban,
          name: transaction.name,
          information: transaction.information,
          description: transaction.description,
          eref: transaction.respond_to?(:eref) ? transaction.eref : transaction.sepa['EREF'],
          mref: transaction.respond_to?(:mref) ? transaction.mref : transaction.sepa['MREF'],
          svwz: transaction.respond_to?(:svwz) ? transaction.svwz : transaction.sepa['SVWZ'],
          creditor_identifier: transaction.respond_to?(:creditor_identifier) ? transaction.creditor_identifier : transaction.sepa['CRED'],
        }
      end
    end
  end
end
