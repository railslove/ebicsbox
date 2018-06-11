require 'grape'

require_relative '../api_endpoint'

# Validations
require_relative '../../../validations/unique_subscriber'

# Helpers
require_relative '../../../helpers/default'

# Entities
require_relative '../../../entities/subscriber'

module Box
  module Apis
    module V2
      class Management < Grape::API
        include ApiEndpoint
        content_type :html, 'text/html'

        namespace '/management/accounts/:iban' do
          before do
            unless env['box.admin']
              error!({ message: 'Unauthorized access. Please provide a valid organization management token!' }, 401)
            end
          end

          desc 'Service', hidden: true
          get '/' do
            { message: 'not yet implemented' }
          end

          resource :subscribers do
            ###
            ### GET /management/accounts/DExx/subscribers/1/ini_letter
            ###
            desc 'Retrieve a list of all subscribers for given account',
              tags: ['subscriber management'],
              headers: AUTH_HEADERS,
              failure: DEFAULT_ERROR_RESPONSES,
              produces: ['application/vnd.ebicsbox-v2+json']

            params do
              requires :iban, type: String, desc: 'IBAN for the account'
              requires :id, type: Integer, desc: 'ID of the subscriber'
            end
            get ':id/ini_letter' do
              subscriber = Subscriber.join(:accounts, id: :account_id).where(organization_id: current_organization.id, iban: params[:iban]).first!(Sequel.qualify(:subscribers, :id) => params[:id])
              if subscriber.ini_letter.nil?
                error!({ message: 'Subscriber setup not yet initiated!' }, 412)
              else
                content_type 'text/html'
                subscriber.ini_letter
              end
            end

            ###
            ### GET /management/accounts/DExx/subscribers
            ###
            desc 'Retrieve a list of all subscribers for given account',
              tags: ['subscriber management'],
              headers: AUTH_HEADERS,
              success: Entities::Subscriber,
              failure: DEFAULT_ERROR_RESPONSES,
              produces: ['application/vnd.ebicsbox-v2+json']

            params do
              requires :iban, type: String, desc: 'IBAN for the account'
            end
            get do
              account = current_organization.accounts_dataset.first!(iban: params[:iban])
              present account.subscribers, with: Entities::Subscriber
            end

            ###
            ### POST /management/accounts/DExx/subscribers
            ###
            desc 'Add a subscriber to given account',
              tags: ['subscriber management'],
              body_name: 'body',
              headers: AUTH_HEADERS,
              success: Entities::Subscriber,
              failure: DEFAULT_ERROR_RESPONSES,
              produces: ['application/vnd.ebicsbox-v2+json']

            params do
              requires :iban, type: String, desc: 'IBAN for the account'
              requires :user_id, type: Integer, desc: "Internal user identifier to associate the subscriber with", documentation: { param_type: 'body' }
              requires :ebics_user, type: String, unique_subscriber: true, desc: "EBICS user to represent"
            end
            post do
              account = current_organization.accounts_dataset.first!(iban: params[:iban])
              declared_params = declared(params)
              ebics_user = declared_params.delete(:ebics_user)
              subscriber = account.add_subscriber(declared_params.merge(remote_user_id: ebics_user))
              if subscriber
                if subscriber.setup!
                  present subscriber, with: Entities::Subscriber
                else
                  subscriber.destroy
                  error!({ message: 'Failed to setup subscriber. Make sure your data is valid and retry!' }, 412)
                end
              else
                error!({ message: 'Failed to create subscriber' }, 400)
              end
            end
          end
        end
      end
    end
  end
end
