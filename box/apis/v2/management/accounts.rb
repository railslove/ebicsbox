# frozen_string_literal: true

require 'grape'

require_relative '../api_endpoint'

# Validations
require_relative '../../../validations/unique_account'
require_relative '../../../validations/active_account'

# Helpers
require_relative '../../../helpers/default'

# Entities
require_relative '../../../entities/management_account'

module Box
  module Apis
    module V2
      module Management
        class Accounts < Grape::API
          include ApiEndpoint
          content_type :html, 'text/html'

          namespace :management do
            before do
              unless env['box.admin']
                error!({ message: 'Unauthorized access. Please provide a valid organization management token!' }, 401)
              end
            end

            desc 'Service', hidden: true
            get '/' do
              { message: 'not yet implemented' }
            end

            resource :accounts do
              ###
              ### GET /management/accounts
              ###
              desc 'Retrieve a list of all onboarded accounts',
                   tags: ['account management'],
                   is_array: true,
                   headers: AUTH_HEADERS,
                   success: Entities::ManagementAccount,
                   failure: DEFAULT_ERROR_RESPONSES,
                   produces: ['application/vnd.ebicsbox-v2+json']

              get do
                accounts = current_organization.accounts_dataset.order(:name).all
                present accounts, with: Entities::ManagementAccount
              end

              ###
              ### GET /management/accounts/DExx
              ###
              desc 'Retrieve a single account by its IBAN',
                   tags: ['account management'],
                   headers: AUTH_HEADERS,
                   success: Entities::ManagementAccount,
                   failure: DEFAULT_ERROR_RESPONSES,
                   produces: ['application/vnd.ebicsbox-v2+json']

              params do
                requires :iban, type: String
              end
              get ':iban' do
                account = current_organization.accounts_dataset.first!(iban: params[:iban])
                present account, with: Entities::ManagementAccount, type: 'full'
              rescue Sequel::NoMatchingRow
                error!({ message: 'Your organization does not have an account with given IBAN!' }, 404)
              end

              ###
              ### POST /management/accounts
              ###
              desc 'Create a new account',
                   tags: ['account management'],
                   body_name: 'body',
                   headers: AUTH_HEADERS,
                   success: Entities::ManagementAccount,
                   failure: DEFAULT_ERROR_RESPONSES,
                   produces: ['application/vnd.ebicsbox-v2+json']

              params do
                requires :name, type: String, unique_account: true, allow_blank: false, desc: 'Internal description of account', documentation: { param_type: 'body' }
                requires :iban, type: String, unique_account: true, allow_blank: false, desc: 'IBAN'
                requires :bic, type: String, allow_blank: false, desc: 'BIC'
                optional :bankname, type: String, desc: 'Name of bank (for internal purposes)'
                optional :creditor_identifier, type: String, desc: 'creditor_identifier'
                optional :callback_url, type: String, desc: 'callback_url'
                optional :host, type: String, desc: 'host'
                optional :partner, type: String, desc: 'partner'
                optional :url, type: String, desc: 'url'
                optional :mode, type: String, desc: 'mode'
              end
              post do
                account = current_organization.add_account(declared(params))
                if account
                  Event.account_created(account)
                  present account, with: Entities::ManagementAccount
                else
                  error!({ message: 'Failed to create account' }, 400)
                end
              end

              ###
              ### PUT /management/accounts/DExx
              ###
              desc 'Update an existing account',
                   tags: ['account management'],
                   headers: AUTH_HEADERS,
                   success: Entities::ManagementAccount,
                   failure: DEFAULT_ERROR_RESPONSES,
                   produces: ['application/vnd.ebicsbox-v2+json']

              params do
                optional :name, type: String, unique_account: true, allow_blank: false, desc: 'Internal description of account', documentation: { param_type: 'body' }
                optional :bankname, type: String, desc: 'Name of bank (for internal purposes)'
                optional :creditor_identifier, type: String, desc: 'creditor_identifier'
                optional :callback_url, type: String, desc: 'callback_url'
                optional :host, type: String, desc: 'host'
                optional :partner, type: String, desc: 'partner'
                optional :url, type: String, desc: 'url'
              end
              put ':iban' do
                account = current_organization.accounts_dataset.first!(iban: params[:iban])
                account.set(declared(params))
                if !account.modified? || account.save
                  present account, with: Entities::ManagementAccount
                else
                  error!({ message: 'Failed to update account' }, 400)
                end
              rescue Sequel::NoMatchingRow
                error!({ message: 'Your organization does not have an account with given IBAN!' }, 404)
              end
            end
          end
        end
      end
    end
  end
end
