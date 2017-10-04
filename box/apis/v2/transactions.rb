require 'grape'

require_relative './api_endpoint'
require_relative '../../entities/v2/transaction'

module Box
  module Apis
    module V2
      class Transactions < Grape::API
        include ApiEndpoint

        resource :transactions do
          desc "Fetch a list of transactions",
            is_array: true,
            headers: AUTH_HEADERS,
            success: Entities::V2::Transaction,
            failure: DEFAULT_ERROR_RESPONSES,
            produces: ['application/vnd.ebicsbox-v2+json']

          params do
            optional :page, type: Integer, desc: "page through the results", default: 1
            optional :per_page, type: Integer, desc: "how many results per page", values: 1..100, default: 10
            optional :iban, type: Array[String], desc: "IBAN of an account", coerce_with: ->(value) { value.split(',') }, documentation: { param_type: 'query' }
            optional :type, type: String, desc: "Type of statement", values: ['credit', 'debit']
            optional :from, type: Date, desc: "Date from which on to filter the results"
            optional :to, type: Date, desc: "Date to which filter results"
          end

          get do
            query = Box::Statement.by_organization(current_organization).filtered(declared(params))
            setup_pagination_header(query.count)
            present query.paginate(declared(params)).all, with: Entities::V2::Transaction
          end
        end
      end
    end
  end
end
