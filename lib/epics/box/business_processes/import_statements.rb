require 'cmxl'
require 'camt_parser'

require_relative '../models/account'
require_relative '../models/bank_statement'
require_relative '../models/event'

module Epics
  module Box
    module BusinessProcesses
      class ImportStatements
        PARSERS = { 'mt940' => Cmxl, 'camt53' => CamtParser::String }

        def self.parse_bank_statement(bank_statement)
          parser = PARSERS.fetch(bank_statement.account.statements_format, Cmxl)
          parser.parse(bank_statement.content).first.transactions
        end

        def self.from_bank_statement(bank_statement)
          bank_transactions = self.parse_bank_statement(bank_statement)

          # We need to pass down index and bank statement sequence to create better checksums
          statements = bank_transactions.each.with_index.map do |bank_transaction, i|
            unique_identifier = [bank_statement.remote_account, bank_statement.sequence, i]
            create_statement(bank_statement.account, bank_transaction, bank_statement.id, unique_identifier)
          end

          stats = { total: bank_transactions.count, imported: statements.select(&:present?).count }
          Box.logger.debug { "[BusinessProcesses::ImportStatements] Imported statements from bank statement. total=#{stats[:total]} imported=#{stats[:imported]}" }
          stats
        end


        def self.create_statement(account, bank_transaction, bank_statement_id, unique_identifier)
          trx = statement_attributes_from_bank_transaction(bank_transaction, unique_identifier)

          if statement = account.statements_dataset.where(sha: trx[:sha]).first
            Box.logger.debug("[BusinessProcesses::ImportStatements] Already imported. sha='#{statement.sha}'")
            false
          else
            statement = account.add_statement(trx.merge(bank_statement_id: bank_statement_id))
            Event.statement_created(statement)
            link_statement_to_transaction(account, statement)
            true
          end
        end

        def self.link_statement_to_transaction(account, statement)
          if transaction = account.transactions_dataset.where(eref: statement.eref).first
            transaction.add_statement(statement)

            if statement.credit?
              transaction.set_state_from("credit_received")
            elsif statement.debit?
              transaction.set_state_from("debit_received")
            end
          end
        end

        def self.checksum(transaction, unique_identifier)
          payload = [
            unique_identifier, # composed of bank statement sequence and position on statement, account
            transaction.date,
            transaction.amount_in_cents,
          ]
          Digest::SHA2.hexdigest(payload.flatten.join).to_s
        end

        def self.statement_attributes_from_bank_transaction(transaction, unique_statement_id)
          {
            sha: checksum(transaction, unique_statement_id),
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
            eref: transaction.sepa["EREF"],
            mref: transaction.sepa["MREF"],
            svwz: transaction.sepa["SVWZ"],
            creditor_identifier: transaction.sepa["CRED"],
          }
        end

      end
    end
  end
end
