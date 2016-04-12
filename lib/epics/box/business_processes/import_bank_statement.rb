require 'cmxl'

require_relative '../models/account'
require_relative '../models/bank_statement'

module Epics
  module Box
    module BusinessProcesses
      class ImportBankStatement
        InvalidInput = Class.new(ArgumentError)

        def self.import_all_from_mt940(raw_mt940, account)
          Cmxl.parse(raw_mt940).map do |raw_bank_statement|
            begin
              BusinessProcesses::ImportBankStatement.from_cmxl(raw_bank_statement, account)
            rescue BusinessProcesses::ImportBankStatement::InvalidInput => ex
              nil # ignore
            end
          end.compact
        end

        # There are cases where we only have the raw mt940 file.
        def self.from_mt940(raw_mt940, account)
          mt940_chunk = Cmxl.parse(raw_mt940).first
          self.from_cmxl(mt940_chunk, account)
        end

        # In case we already have a fully parsed MT940 file
        def self.from_cmxl(raw_bank_statement, account)
          verify_arguments(raw_bank_statement, account)
          bank_statement = find_or_create_bank_statement(raw_bank_statement, account)
          update_meta_data(raw_bank_statement, account)
          return bank_statement
        end

        def self.verify_arguments(raw_bank_statement, account)
          fail(InvalidInput, 'Cannot import empty bank statement.') if raw_bank_statement.blank?
          fail(InvalidInput, 'Cannot import bank statement for unknown sub-account.') unless valid_account?(raw_bank_statement, account)
        end

        # This is required as Deutsche Bank has a very weird MT940 file format
        def self.valid_account?(raw_bank_statement, account)
          account_number = raw_bank_statement.account_identification.account_number
          !(!(account.iban.end_with?(account_number) || (account.iban + "00").end_with?(account_number)))
        end

        def self.find_or_create_bank_statement(raw_bank_statement, account)
          BankStatement.find_or_create(account_id: account.id, sequence: (raw_bank_statement.try(:electronic_sequence_number) || raw_bank_statement.legal_sequence_number)) do |bs|
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
          if account.balance_date.blank? || account.balance_date <= balance.date
            account.set_balance(balance.date, balance.amount_in_cents)
          end
        end

        def self.as_big_decimal(input)
          return if input.nil?
          (input.amount * input.sign).to_d
        end
      end
    end
  end
end
