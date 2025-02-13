require_relative "account"

module DataMapping
  module Cmxl
    class Statement
      attr_reader :raw_bank_statement

      delegate :account_number,
        :blank?,
        :closing_or_intermediary_balance,
        :opening_or_intermediary_balance,
        :source,
        :transactions,
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
    end
  end
end
