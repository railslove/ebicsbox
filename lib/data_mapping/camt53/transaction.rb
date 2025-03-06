module DataMapping
  module Camt53
    class Transaction
      attr_reader :raw_bank_statement, :first_transaction

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
        @first_transaction = raw_bank_statement.transactions.first
      end

      def bic
        first_transaction.bic
      end

      def creditor_identifier
        first_transaction.creditor_identifier
      end

      def date
        raw_bank_statement.value_date
      end

      def description
        raw_bank_statement.additional_information
      end

      def entry_date
        raw_bank_statement.booking_date
      end

      def eref
        first_transaction.end_to_end_reference
      end

      def iban
        first_transaction.iban
      end

      def information
        first_transaction.payment_information
      end

      def mref
        first_transaction.mandate_reference
      end

      def name
        first_transaction.name
      end

      def svwz
        first_transaction.remittance_information
      end

      def swift_code
        first_transaction.swift_code
      end

      def transaction_id
        first_transaction.transaction_id
      end
    end
  end
end
