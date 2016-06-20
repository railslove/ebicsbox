require 'grape'

require_relative './api_endpoint'
require_relative '../../business_processes/new_account'
require_relative '../../entities/v2/account'
require_relative '../../validations/unique_account'


module Box
  module Apis
    module V2
      class Accounts < Grape::API
        include ApiEndpoint

        content_type :html, 'text/html'

        rescue_from Sequel::NoMatchingRow do |e|
          error!({ message: 'Your organization does not have an account with given IBAN!' }, 404)
        end

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
            query = Account.by_organization(current_organization).filtered(declared(params))
            setup_pagination_header(query.count)
            present query.paginate(declared(params)).all, with: Entities::V2::Account
          end


          ###
          ### POST /accounts
          ###

          params do
            requires :name, type: String, allow_blank: false, desc: 'Internal description of account'
            requires :iban, type: String, unique_account: true, allow_blank: false, desc: 'IBAN'
            requires :bic, type: String, allow_blank: false, desc: 'BIC'
            requires :host, type: String, desc: 'EBICS HOSTID as provided by financial institution'
            requires :partner, type: String, desc: 'EBICS PARTNERID as provided by financial institution'
            requires :url, type: String, desc: 'EBICS server url'
            requires :subscriber, type: String, desc: 'EBICS subscriber as provided by financial institution'
            optional :creditor_identifier, type: String, desc: 'Creditor identifier required for direct debits'
            optional :callback_url, type: String, desc: 'URL to which webhooks are delivered'
          end
          post do
            begin
              account = BusinessProcesses::NewAccount.create!(current_organization, current_user, declared(params, include_missing: false))
              {
                message: "Account created successfully. Please fetch INI letter, sign it, and submit it to your bank",
                account: Entities::V2::Account.represent(account),
              }
            rescue BusinessProcesses::NewAccount::EbicsError => ex
              error!({ message: 'Failed to setup subscriber with your bank. Make sure your data is valid and retry!' }, 412)
            rescue => ex
              error!({ message: 'Failed to create account' }, 400)
            end
          end


          ###
          ### GET /accounts/:iban
          ###

          params do
            requires :iban, type: String
          end
          get ':iban' do
            account = Box::Account.by_organization(current_organization).first!(iban: params[:iban])
            present account, with: Entities::V2::Account
          end


          ###
          ### GET /accounts/:iban/ini_letter
          ###

          get ':iban/ini_letter' do
            account = Box::Account.by_organization(current_organization).first!(iban: params[:iban])
            subscriber = account.subscriber_for(current_user.id)
            if subscriber.ini_letter.nil?
              error!({ message: 'Subscriber setup not yet initiated!' }, 412)
            else
              content_type 'text/html'
              subscriber.ini_letter
            end
          end


          ###
          ### PUT /accounts/:iban
          ###

          params do
            optional :name, type: String, allow_blank: false, desc: 'Internal description of account'
            optional :creditor_identifier, type: String, desc: 'Creditor identifier required for direct debits'
            optional :callback_url, type: String, desc: 'URL to which webhooks are delivered'
          end
          put ':iban' do
            account = current_organization.accounts_dataset.first!(iban: params[:iban])
            account.set(declared(params, include_missing: false))
            if !account.modified? || account.save
              {
                message: "Account updated successfully.",
                account: Entities::V2::Account.represent(account),
              }
            else
              error!({ message: 'Failed to update account' }, 400)
            end
          end
        end
      end
    end
  end
end
