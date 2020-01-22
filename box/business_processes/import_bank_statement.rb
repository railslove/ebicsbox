# frozen_string_literal: true

require 'cmxl'

require_relative '../models/account'
require_relative '../models/bank_statement'
require_relative '../../lib/checksum_generator'

# more general matching regex that covers both newlines and newlines with dashes
Cmxl.config[:statement_separator] = /(\n-?)(?=:20)/m

module Box
  module BusinessProcesses
    class ImportBankStatement
      InvalidInput = Class.new(ArgumentError)

      def self.import_all_from_mt940(raw_mt940, account)
        Cmxl.parse(raw_mt940).map do |raw_bank_statement|
          from_cmxl(raw_bank_statement, account)
        rescue InvalidInput => _ex
          nil # ignore
        end.compact
      end

      # There are cases where we only have the raw mt940 file.
      def self.from_mt940(raw_mt940, account)
        mt940_chunk = Cmxl.parse(raw_mt940).first
        from_cmxl(mt940_chunk, account)
      end

      # In case we already have a fully parsed MT940 file
      def self.from_cmxl(raw_bank_statement, account)
        validate_params(raw_bank_statement, account)
        bank_statement = find_or_create_bank_statement(raw_bank_statement, account)
        update_meta_data(raw_bank_statement, account)
        bank_statement
      end

      def self.validate_params(raw_bank_statement, account)
        raise(InvalidInput, 'Cannot import empty bank statement.') if raw_bank_statement.blank?

        validate_account!(raw_bank_statement, account)
      end

      # This is required as Deutsche Bank has a very weird MT940 file format
      def self.validate_account!(raw_bank_statement, account)
        account_number = raw_bank_statement.account_identification.account_number
        return if account.iban.end_with?(account_number) || (account.iban + '00').end_with?(account_number)

        raise(InvalidInput, "Cannot import bank statement for unknown sub-account #{account_number}.")
      end

      def self.find_or_create_bank_statement(raw_bank_statement, account)
        BankStatement.find_or_create(sha: checksum(raw_bank_statement, account)) do |bs|
          bs.account_id = account.id
          bs.sequence = raw_bank_statement.try(:electronic_sequence_number) || raw_bank_statement.legal_sequence_number
          bs.year = extract_year_from_bank_statement(raw_bank_statement)
          bs.remote_account = raw_bank_statement.account_identification.source
          bs.opening_balance = as_big_decimal(raw_bank_statement.opening_or_intermediary_balance) # this will be final or intermediate
          bs.closing_balance = as_big_decimal(raw_bank_statement.closing_or_intermediary_balance) # this will be final or intermediate
          bs.transaction_count = raw_bank_statement.transactions.count
          bs.fetched_on = Date.today
          bs.content = raw_bank_statement.source
        end
      end

      def self.update_meta_data(raw_bank_statement, account)
        balance = raw_bank_statement.closing_or_intermediary_balance # We have to handle both final and intermediary balances
        return unless balance # vmk do not have a closing balance and thus cannot update it

        if account.balance_date.blank? || account.balance_date <= balance.date
          account.set_balance(balance.date, balance.amount_in_cents)
        end
      end

      def self.as_big_decimal(input)
        return if input.nil?

        (input.amount * input.sign).to_d
      end

      def self.extract_year_from_bank_statement(raw_bank_statement)
        first_transaction = raw_bank_statement.transactions.first
        first_transaction&.date&.year
      end

      def self.checksum(raw_bank_statement, account)
        payload = [
          account.id,
          extract_year_from_bank_statement(raw_bank_statement),
          raw_bank_statement.source
        ]

        ChecksumGenerator.from_payload(payload)
      end
    end
  end
end
