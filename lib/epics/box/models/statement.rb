require_relative '../models/account'
require_relative '../models/bank_statement'
require_relative '../models/transaction'
require_relative '../entities/statement'

module Epics
  module Box
    class Statement < Sequel::Model
      many_to_one :account
      many_to_one :bank_statement
      many_to_one :transaction

      def self.generic_filter(query, account_id:, transaction_id: nil, from: nil, to: nil, type: nil, **unused)
        # Filter by account id
        query = query.where(account_id: account_id)

        # Filter by transaction id
        query = query.where(transaction_id: transaction_id) if transaction_id.present?

        # Filter by statement date
        query = query.where("statements.date >= ?", from) if from.present?
        query = query.where("statements.date <= ?", to) if to.present?

        # Filter by type
        query = query.where(debit: type == 'debit') if type.present?

        query
      end

      def self.count_by_account(**generic_filters)
        query = generic_filter(self, generic_filters)
        query.count
      end

      def self.paginated_by_account(per_page: 10, page: 1, **generic_filters)
        query = self.limit(per_page).offset((page - 1) * per_page).reverse_order(:date)
        generic_filter(query, generic_filters)
      end

      def credit?
        !debit?
      end

      def debit?
        self.debit
      end

      def type
        debit? ? 'debit' : 'credit'
      end

      def as_event_payload
        {
          account_id: account_id,
          statement: Entities::Statement.represent(self).as_json,
        }
      end
    end
  end
end
