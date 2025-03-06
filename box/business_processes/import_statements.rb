# frozen_string_literal: true

require "sepa_file_parser"

require_relative "../models/account"
require_relative "../models/bank_statement"
require_relative "../models/event"
require_relative "../../lib/checksum_generator"
require_relative "../../lib/data_mapping/statement_factory"

module Box
  module BusinessProcesses
    class ImportStatements
      PARSERS = {"mt940" => Cmxl, "camt53" => SepaFileParser::Camt053::Statement}.freeze

      def self.from_bank_statement(bank_statement, upcoming = false)
        bank_transactions = parse_bank_statement(bank_statement)

        statements = bank_transactions.map do |bank_transaction|
          create_statement(bank_statement, bank_transaction, upcoming)
        end

        stats = {total: bank_transactions.count, imported: statements.count(&:present?)}
        Box.logger.info { "[BusinessProcesses::ImportStatements] Imported statements from bank statement. total=#{stats[:total]} imported=#{stats[:imported]}" }
        stats
      end

      def self.parse_bank_statement(bank_statement)
        parser = PARSERS.fetch(bank_statement.account.statements_format, Cmxl)
        result = parser.parse(bank_statement.content)
        statement_data = result.is_a?(Array) ? result.first : result
        statement = DataMapping::StatementFactory.new(statement_data, bank_statement.account).call
        statement.transactions
      end

      def self.create_statement(bank_statement, bank_transaction, upcoming = false)
        account = bank_statement.account
        trx = statement_attributes_from_bank_transaction(bank_transaction, bank_statement)

        statement = account.statements_dataset.first(sha: trx[:sha])
        if statement
          Box.logger.debug("[BusinessProcesses::ImportStatements] Already imported. sha='#{statement.sha}'")
          statement.update(settled: true) unless upcoming
          false
        else
          statement = account.add_statement(trx.merge(bank_statement_id: bank_statement.id, settled: !upcoming))
          Event.statement_created(statement)
          link_statement_to_transaction(account, statement)
          true
        end
      end

      def self.link_statement_to_transaction(account, statement)
        # find transactions via EREF
        transaction = account.transactions_dataset.where(eref: statement.eref).first
        # fallback to finding via statement information
        transaction ||= account.transactions_dataset.exclude(currency: "EUR", status: %w[credit_received debit_received]).where { created_at > 14.days.ago }.detect { |t| statement.information =~ /#{t.eref}/i }

        return unless transaction

        transaction.add_statement(statement)

        if statement.credit?
          transaction.update_status("credit_received")
        elsif statement.debit?
          transaction.update_status("debit_received")
        end
      end

      def self.checksum(transaction, bank_statement)
        checksum_payload = checksum_attributes(transaction, bank_statement.remote_account)
        ChecksumGenerator.from_payload(checksum_payload)
      end

      def self.checksum_attributes(transaction, remote_account)
        return [remote_account, transaction.transaction_id] if transaction.transaction_id.present?

        payload_from_transaction_attributes(transaction, remote_account)
      end

      def self.payload_from_transaction_attributes(transaction, remote_account)
        [
          remote_account,
          transaction.date,
          transaction.amount_in_cents,
          transaction.iban,
          transaction.name,
          transaction.sign,
          transaction.eref,
          transaction.mref,
          transaction.svwz,
          transaction.information.gsub(/\s/, "")
        ]
      end

      def self.statement_attributes_from_bank_transaction(transaction, bank_statement)
        {
          amount: transaction.amount_in_cents,
          bank_reference: transaction.bank_reference,
          bic: transaction.bic,
          creditor_identifier: transaction.creditor_identifier,
          date: transaction.date,
          debit: transaction.debit?,
          description: transaction.description,
          entry_date: transaction.entry_date,
          eref: transaction.eref,
          iban: transaction.iban,
          information: transaction.information,
          mref: transaction.mref,
          name: transaction.name,
          reference: transaction.reference,
          sha: checksum(transaction, bank_statement),
          sign: transaction.sign,
          svwz: transaction.svwz,
          swift_code: transaction.swift_code,
          tx_id: transaction.transaction_id
        }
      end
    end
  end
end
