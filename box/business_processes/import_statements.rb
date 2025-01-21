# frozen_string_literal: true

require "camt_parser"

require_relative "../models/account"
require_relative "../models/bank_statement"
require_relative "../models/event"
require_relative "../../lib/checksum_generator"

module Box
  module BusinessProcesses
    class ImportStatements
      PARSERS = {"mt940" => Cmxl, "camt53" => CamtParser::Format053::Statement}.freeze

      def self.parse_bank_statement(bank_statement)
        parser = PARSERS.fetch(bank_statement.account.statements_format, Cmxl)
        result = parser.parse(bank_statement.content)
        result.is_a?(Array) ? result.first.transactions : result.transactions
      end

      def self.from_bank_statement(bank_statement, upcoming = false)
        bank_transactions = parse_bank_statement(bank_statement)

        statements = bank_transactions.map do |bank_transaction|
          create_statement(bank_statement, bank_transaction, upcoming)
        end

        stats = {total: bank_transactions.count, imported: statements.count(&:present?)}
        Box.logger.info { "[BusinessProcesses::ImportStatements] Imported statements from bank statement. total=#{stats[:total]} imported=#{stats[:imported]}" }
        stats
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
        ChecksumGenerator.from_payload(checksum_attributes(transaction, bank_statement.remote_account))
      end

      def self.checksum_attributes(transaction, remote_account)
        return [remote_account, transaction.transaction_id] if transaction.try(:transaction_id).present?

        payload_from_transaction_attributes(transaction, remote_account)
      end

      def self.payload_from_transaction_attributes(transaction, remote_account)
        eref = transaction.respond_to?(:eref) ? transaction.eref : transaction.sepa["EREF"]
        mref = transaction.respond_to?(:mref) ? transaction.mref : transaction.sepa["MREF"]
        svwz = transaction.respond_to?(:svwz) ? transaction.svwz : transaction.sepa["SVWZ"]

        [
          remote_account,
          transaction.date,
          transaction.amount_in_cents,
          transaction.iban,
          transaction.name,
          transaction.sign,
          eref,
          mref,
          svwz,
          transaction.information.gsub(/\s/, "")
        ]
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
          eref: transaction.respond_to?(:eref) ? transaction.eref : transaction.sepa["EREF"],
          mref: transaction.respond_to?(:mref) ? transaction.mref : transaction.sepa["MREF"],
          svwz: transaction.respond_to?(:svwz) ? transaction.svwz : transaction.sepa["SVWZ"],
          tx_id: transaction.try(:primanota) || transaction.try(:transaction_id),
          creditor_identifier: transaction.respond_to?(:creditor_identifier) ? transaction.creditor_identifier : transaction.sepa["CRED"],
          expected: transaction.expected?,
          reversal: transaction.reversal?,
        }
      end
    end
  end
end
