module DataMapping
  module Cmxl
    class Statement
      attr_reader :raw_bank_statement

      delegate :account_identification,
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
    end
  end
end
