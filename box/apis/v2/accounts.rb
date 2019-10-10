# frozen_string_literal: true

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

        rescue_from Sequel::NoMatchingRow do |_e|
          error!({ message: 'Your organization does not have an account with given IBAN!' }, 404)
        end

        resource :accounts do
          ###
          ### GET /accounts
          ###
          desc 'Fetch a list of accounts',
               is_array: true,
               headers: AUTH_HEADERS,
               success: Entities::V2::Account,
               failure: DEFAULT_ERROR_RESPONSES,
               produces: ['application/vnd.ebicsbox-v2+json']

          params do
            optional :page, type: Integer, desc: 'page through the results', default: 1
            optional :per_page, type: Integer, desc: 'how many results per page', values: 1..100, default: 10
            optional :status, type: String, desc: 'Filter accounts by their activation status', default: 'all'
          end

          get do
            query = Account.by_organization(current_organization).filtered(declared(params))
            setup_pagination_header(query.count)
            present query.paginate(declared(params)).all, with: Entities::V2::Account
          end

          ###
          ### POST /accounts
          ###
          desc 'Create a new account',
               headers: AUTH_HEADERS,
               success: Message,
               body_name: 'body',
               failure: DEFAULT_ERROR_RESPONSES,
               produces: ['application/vnd.ebicsbox-v2+json']

          params do
            requires :name, type: String, allow_blank: false, desc: 'Name of the account', documentation: { param_type: 'body' }
            requires :iban, type: String, unique_account: true, allow_blank: false, desc: 'IBAN'
            requires :bic, type: String, allow_blank: false, desc: 'BIC'
            requires :host, type: String, desc: 'EBICS HOSTID as provided by financial institution'
            requires :partner, type: String, desc: 'EBICS PARTNERID as provided by financial institution'
            requires :url, type: String, desc: 'EBICS server url'
            requires :ebics_user, type: String, desc: 'EBICS ebics_user as provided by financial institution'
            optional :descriptor, type: String, allow_blank: false, desc: 'Internal descriptor of account'
            optional :creditor_identifier, type: String, desc: 'Creditor identifier required for direct debits'
            optional :callback_url, type: String, desc: 'URL to which webhooks are delivered'
          end
          post do
            account = BusinessProcesses::NewAccount.create!(current_organization, current_user, declared(params, include_missing: false))
            {
              message: 'Account created successfully. Please fetch INI letter, sign it, and submit it to your bank',
              account: Entities::V2::Account.represent(account)
            }
          rescue BusinessProcesses::NewAccount::EbicsError => _ex
            error!({ message: 'Failed to setup ebics_user with your bank. Make sure your data is valid and retry!' }, 412)
          rescue StandardError => _ex
            error!({ message: 'Failed to create account' }, 400)
          end

          ###
          ### GET /accounts/:iban
          ###

          desc 'Fetch an account',
               headers: AUTH_HEADERS,
               success: Entities::V2::Account,
               failure: DEFAULT_ERROR_RESPONSES,
               produces: ['application/vnd.ebicsbox-v2+json']

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

          desc 'Fetch the ini letter of an account',
               headers: AUTH_HEADERS,
               failure: DEFAULT_ERROR_RESPONSES,
               produces: ['text/html']

          params do
            requires :iban, type: String
          end
          get ':iban/ini_letter' do
            account = Box::Account.by_organization(current_organization).first!(iban: params[:iban])
            ebics_user = account.ebics_user_for(current_user.id)
            if ebics_user.ini_letter.nil?
              error!({ message: 'EbicsUser setup not yet initiated!' }, 412)
            else
              content_type 'text/html'
              ebics_user.ini_letter
            end
          end

          ###
          ### PUT /accounts/:iban
          ###

          desc 'Update an account',
               success: Entities::V2::Account,
               headers: AUTH_HEADERS,
               failure: DEFAULT_ERROR_RESPONSES,
               produces: ['application/vnd.ebicsbox-v2+json'],
               body_name: 'body'

          params do
            optional :name, type: String, allow_blank: false, desc: 'Name of account', documentation: { param_type: 'body' }
            optional :descriptor, type: String, allow_blank: false, desc: 'Internal descriptor of account'
            optional :creditor_identifier, type: String, desc: 'Creditor identifier required for direct debits'
            optional :callback_url, type: String, desc: 'URL to which webhooks are delivered'
          end
          put ':iban' do
            account = current_organization.accounts_dataset.first!(iban: params[:iban])
            account.set(declared(params, include_missing: false))
            if !account.modified? || account.save
              {
                message: 'Account updated successfully.',
                account: Entities::V2::Account.represent(account)
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
