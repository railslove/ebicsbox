module DataMapping
  module Cmxl
    class Account
      attr_reader :raw_bank_statement

      delegate :account_number,
        to: :raw_bank_statement

      def initialize(raw_bank_statement)
        @raw_bank_statement = raw_bank_statement
      end

      def iban
        return raw_bank_statement.iban if raw_bank_statement.iban.present?
        raw_bank_statement.source
      end
    end
  end
end
