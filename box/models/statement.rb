# frozen_string_literal: true

require "json"
require "sequel"

require_relative "../models/account"
require_relative "../models/bank_statement"
require_relative "../models/transaction"
require_relative "../entities/statement"

module Box
  class Statement < Sequel::Model
    many_to_one :account
    many_to_one :bank_statement
    many_to_one :transaction

    dataset_module do
      def by_organization(organization)
        left_join(:accounts, id: :account_id)
          .where(accounts__organization_id: organization.id)
          .select_all(:statements)
      end

      def filtered(params)
        query = self

        # Filter by account id
        query = query.where(accounts__iban: params[:iban]) if params[:iban].present?

        # Filter by statement date
        query = query.where { statements__date >= params[:from] } if params[:from].present?
        query = query.where { statements__date <= params[:to] } if params[:to].present?

        # Filter by eref
        query = query.where(eref: params[:end_to_end_reference]) if params[:end_to_end_reference].present?

        # Filter by type
        query = query.where(debit: params[:type] == "debit") if params[:type].present?

        query
      end

      def paginate(params)
        limit(params[:per_page])
          .offset((params[:page] - 1) * params[:per_page])
          .reverse_order(:date, :id)
      end
    end

    class << self
      def generic_filter(query, account_id: nil, transaction_id: nil, from: nil, to: nil, type: nil, **_unused)
        # Filter by account id
        query = query.where(account_id: account_id) if account_id.present?

        # Filter by transaction id
        query = query.where(transaction_id: transaction_id) if transaction_id.present?

        # Filter by statement date
        query = query.where { statements__date >= from } if from.present?
        query = query.where { statements__date <= to } if to.present?

        # Filter by type
        query = query.where(debit: type == "debit") if type.present?

        query
      end

      def count_by_account(**generic_filters)
        query = generic_filter(self, generic_filters)
        query.count
      end

      def paginated_by_account(per_page: 10, page: 1, **generic_filters)
        query = limit(per_page).offset((page - 1) * per_page).reverse_order(:date, :id)
        generic_filter(query, **generic_filters)
      end
    end

    def credit?
      !debit?
    end

    def debit?
    end

    def reversal?
      reversal
    end

    def expected?
      !!expected
    end

    def type
      debit? ? "debit" : "credit"
    end

    def amount_in_cents
      amount
    end

    def as_event_payload
      {
        id: public_id,
        account_id: account_id,
        statement: Entities::Statement.represent(self).as_json
      }
    end
  end
end
