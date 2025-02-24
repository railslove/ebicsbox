require_relative "account"
require_relative "transaction"

module DataMapping
  module Cmxl
    class Statement
      attr_reader :raw_bank_statement

      delegate :account_number,
        :blank?,
        :closing_or_intermediary_balance,
        :opening_or_intermediary_balance,
        :source,
        to: :raw_bank_statement

      def initialize(raw_bank_statement)
        @raw_bank_statement = raw_bank_statement
      end

      def sequence
        raw_bank_statement.legal_sequence_number
      end

      def account_identification
        Account.new(raw_bank_statement.account_identification)
      end

      def transactions
        raw_bank_statement.transactions.map do |entry|
          Transaction.new(entry)
        end
      end
    end
  end
end
