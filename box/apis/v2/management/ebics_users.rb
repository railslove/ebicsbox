# frozen_string_literal: true

require "grape"

require_relative "../api_endpoint"

# Validations
require_relative "../../../validations/unique_ebics_user"

# Helpers
require_relative "../../../helpers/default"

# Entities
require_relative "../../../entities/ebics_user"

module Box
  module Apis
    module V2
      module Management
        class EbicsUsers < Grape::API
          include ApiEndpoint
          content_type :html, "text/html"

          namespace "/management/accounts/:iban" do
            before do
              unless env["box.admin"]
                error!({message: "Unauthorized access. Please provide a valid organization management token!"}, 401)
              end

              @account = current_organization.accounts_dataset.first!(iban: params[:iban])
            rescue Sequel::NoMatchingRow
              error!({message: "Your organization does not have an account with given IBAN!"}, 404)
            end

            resource :ebics_users do
              ###
              ### GET /management/accounts/DExx/ebics_users/1/ini_letter
              ###
              desc "Retrieve a list of all ebics_users for given account",
                tags: ["ebics_user management"],
                headers: AUTH_HEADERS,
                failure: DEFAULT_ERROR_RESPONSES,
                produces: ["application/vnd.ebicsbox-v2+json"]

              params do
                requires :id, type: Integer, desc: "ID of the ebics_user"
              end
              get ":id/ini_letter" do
                ebics_user = @account.ebics_users_dataset.first!(Sequel.qualify(:ebics_users, :id) => params[:id])
                if ebics_user.ini_letter.nil?
                  error!({message: "EbicsUser setup not yet initiated!"}, 412)
                else
                  content_type "text/html"
                  ebics_user.ini_letter
                end
              end

              params do
                requires :id, type: Integer, desc: "ID of the ebics_user"
              end
              post ":id/refresh_bank_keys" do
                ebics_user = @account.ebics_users_dataset.first!(Sequel.qualify(:ebics_users, :id) => params[:id])
                if ebics_user.refresh_bank_keys!
                  present ebics_user, with: Entities::EbicsUser
                else
                  error!({message: "Bank keys could not be refreshed!"}, 500)
                end
              end

              ###
              ### GET /management/accounts/DExx/ebics_users
              ###
              desc "Retrieve a list of all ebics_users for given account",
                tags: ["ebics_user management"],
                headers: AUTH_HEADERS,
                success: Entities::EbicsUser,
                failure: DEFAULT_ERROR_RESPONSES,
                produces: ["application/vnd.ebicsbox-v2+json"]

              params do
                requires :iban, type: String, desc: "IBAN for the account"
              end

              get do
                present @account.ebics_users, with: Entities::EbicsUser
              end

              ###
              ### POST /management/accounts/DExx/ebics_users
              ###
              desc "Add a ebics_user to given account",
                tags: ["ebics_user management"],
                body_name: "body",
                headers: AUTH_HEADERS,
                success: Entities::EbicsUser,
                failure: DEFAULT_ERROR_RESPONSES,
                produces: ["application/vnd.ebicsbox-v2+json"]

              params do
                requires :iban, type: String, desc: "IBAN for the account"
                requires :user_id, type: Integer, desc: "Internal user identifier to associate the ebics_user with", documentation: {param_type: "body"}
                requires :ebics_user, type: String, unique_ebics_user: true, desc: "EBICS user to represent"
              end
              post do
                ebics_user = @account.add_ebics_user(
                  user_id: declared(params)[:user_id],
                  remote_user_id: declared(params)[:ebics_user],
                  partner: @account.partner
                )
                error!({message: "Failed to create ebics_user"}, 400) unless ebics_user

                if ebics_user.setup!(@account)
                  present ebics_user, with: Entities::EbicsUser
                else
                  ebics_user.destroy
                  error!({message: "Failed to setup ebics_user. Make sure your data is valid and retry!"}, 412)
                end
              end
            end
          end
        end
      end
    end
  end
end
