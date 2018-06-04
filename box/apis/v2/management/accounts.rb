require 'grape'

require_relative '../api_endpoint'

# Validations
require_relative '../../../validations/unique_account'
require_relative '../../../validations/active_account'
require_relative '../../../validations/unique_subscriber'

# Helpers
require_relative '../../../helpers/default'

# Entities
require_relative '../../../entities/management_account'

module Box
  module Apis
    module V2
      class Management < Grape::API
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
              accounts = current_organization.accounts_dataset.all.sort { |a1, a2| a1.name.to_s.downcase <=> a2.name.to_s.downcase }
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
              begin
                account = current_organization.accounts_dataset.first!(iban: params[:iban])
                present account, with: Entities::ManagementAccount, type: 'full'
              rescue Sequel::NoMatchingRow
                error!({ message: 'Your organization does not have an account with given IBAN!' }, 400)
              end
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
              if account = current_organization.add_account(params)
                Event.account_created(account)
                present account, with: Entities::ManagementAccount
              else
                error!({ message: 'Failed to create account' }, 400)
              end
            end

            desc 'Setup a newly created account',
              tags: ['account management'],
              headers: AUTH_HEADERS,
              success: Message,
              failure: DEFAULT_ERROR_RESPONSES,
              produces: ['application/vnd.ebicsbox-v2+json']

            params do
              requires :iban, type: String
            end
            put ':iban/setup' do
              begin
                account = current_organization.accounts_dataset.first!(iban: params[:iban])
                account.setup!
              rescue Account::AlreadyActivated
                error!({ message: "Account is already activated" }, 400)
              rescue Account::IncompleteEbicsData
                error!({ message: "Incomplete EBICS setup" }, 400)
              rescue
                error!({ message: "unknown failure" }, 400)
              end
            end

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
              optional :mode, type: String, desc: 'mode'
            end
            put ':iban' do
              begin
                account = current_organization.accounts_dataset.first!(iban: params[:iban])
                account.set(params.except('id', 'state', 'access_token', 'iban', 'bic'))
                if !account.modified? || account.save
                  present account, with: Entities::ManagementAccount
                else
                  error!({ message: 'Failed to update account' }, 400)
                end
              rescue Sequel::NoMatchingRow
                error!({ message: 'Your organization does not have an account with given IBAN!' }, 400)
              end
            end
          end
        end
      end
    end
  end
end
