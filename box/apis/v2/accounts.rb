require 'grape'

require_relative './api_endpoint'
require_relative '../../entities/v2/account'

module Box
  module Apis
    module V2
      class Accounts < Grape::API
        include ApiEndpoint

        resource :accounts do

          ###
          ### GET /accounts
          ###

          params do
            optional :page, type: Integer, desc: "page through the results", default: 1
            optional :per_page, type: Integer, desc: "how many results per page", values: 1..100, default: 10
            optional :status, type: String, desc: "Filter accounts by their activation status", default: 'all'
          end
          get do
            query = Box::Account.by_organization(current_organization).filtered(declared(params))
            setup_pagination_header(query.count)
            present query.paginate(declared(params)).all, with: Entities::V2::Account
          end

          ###
          ### POST /accounts
          ###

          ###
          ### GET /accounts/:iban
          ###

          params do
            requires :iban, type: String
          end
          get ':iban' do
            begin
              account = Box::Account.by_organization(current_organization).first!(iban: params[:iban])
              present account, with: Entities::V2::Account
            rescue Sequel::NoMatchingRow => ex
              error!({ message: 'Your organization does not have an account with given IBAN!' }, 404)
            end
          end

          ###
          ### GET /accounts/:iban/ini_letter
          ###

          ###
          ### PUT /accounts/:iban
          ###

          ###
          ### DELETE /accounts/:iban
          ###
        end
      end
    end
  end
end
