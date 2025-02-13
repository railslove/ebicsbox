module DataMapping
  module Camt53
    class Transaction
      attr_reader :raw_bank_statement

      delegate :amount_in_cents,
        :bank_reference,
        :credit?,
        :debit?,
        :reference,
        :sign,
        :transaction_id,
        to: :raw_bank_statement

      def initialize(raw_bank_statement)
        @raw_bank_statement = raw_bank_statement
      end

      def eref
        raw_bank_statement.transactions.first.end_to_end_reference
      end

      def mref
        raw_bank_statement.transactions.first.mandate_reference
      end

      def svwz
        raw_bank_statement.transactions.first.remittance_information
      end

      def information
        raw_bank_statement.transactions.first.payment_information
      end

      def name
        raw_bank_statement.transactions.first.name
      end

      def swift_code
        raw_bank_statement.transactions.first.swift_code
      end

      def date
        raw_bank_statement.value_date
      end

      def entry_date
        raw_bank_statement.booking_date
      end

      def bic
        raw_bank_statement.transactions.first.bic
      end

      def iban
        raw_bank_statement.transactions.first.iban
      end

      def creditor_identifier
        raw_bank_statement.transactions.first.creditor_identifier
      end

      def transaction_id
        raw_bank_statement.transactions.first.transaction_id
      end

      def description
        raw_bank_statement.additional_information
      end
    end
  end
end
