module DataMapping
  module Cmxl
    class Transaction
      attr_reader :raw_bank_statement

      delegate :amount_in_cents,
        :date,
        :information,
        :name,
        :sepa,
        :sign,
        :bank_reference,
        :bic,
        :iban,
        :credit?,
        :debit?,
        :description,
        :entry_date,
        :reference,
        :swift_code,
        :remote_account,
        to: :raw_bank_statement

      def initialize(raw_bank_statement)
        @raw_bank_statement = raw_bank_statement
      end

      def eref
        raw_bank_statement.sepa["EREF"]
      end

      def mref
        raw_bank_statement.sepa["MREF"]
      end

      def svwz
        raw_bank_statement.sepa["SVWZ"]
      end

      def transaction_id
        raw_bank_statement.primanota
      end

      def creditor_identifier
        raw_bank_statement.sepa["CRED"]
      end
    end
  end
end
