module DataMapping
  module Camt53
    class Statement
      attr_reader :raw_bank_statement

      def initialize(raw_bank_statement)
        @raw_bank_statement = raw_bank_statement
      end

      def blank?
        raw_bank_statement.blank?
      end

      def account_identification
        raw_bank_statement.account_identification
      end

      def closing_or_intermediary_balance
        raw_bank_statement.closing_or_intermediary_balance
      end

      def sequence
        raw_bank_statement.electronic_sequence_number
      end

      def opening_or_intermediary_balance
        raw_bank_statement.closing_or_intermediary_balance
      end

      def source
        raw_bank_statement.source
      end

      def transactions
        raw_bank_statement.transactions
      end
    end
  end
end
