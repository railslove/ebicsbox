# frozen_string_literal: true

require "grape"

require_relative "../api_endpoint"

# Helpers
require_relative "../../../helpers/default"

# Entities
require_relative "../../../entities/v2/organization"

module Box
  module Apis
    module V2
      module Management
        class Organizations < Grape::API
          include ApiEndpoint
          content_type :html, "text/html"

          namespace :management do
            before do
              unless env["box.admin"]
                error!({message: "Unauthorized access. Please provide a valid organization management token!"}, 401)
              end
            end

            desc "Service", hidden: true
            get "/" do
              {message: "not yet implemented"}
            end

            resource :organizations do
              # create
              desc "Create a new organization",
                tags: ["organization management"],
                body_name: "body",
                headers: AUTH_HEADERS,
                success: Entities::V2::Organization,
                failure: DEFAULT_ERROR_RESPONSES,
                produces: ["application/vnd.ebicsbox-v2+json"]

              params do
                requires :name, type: String, allow_blank: false, desc: "The organization's display name"
                requires :user, type: Hash do
                  requires :name, type: String, allow_blank: false, desc: "The user's display name"
                  optional :access_token, type: String, desc: "Set a custom access token"
                end
                optional :webhook_token, type: String, desc: "Token to sign organization's webhook payloads"
              end
              post do
                DB.transaction do
                  organization = Organization.register(declared(params).except(:user))
                  organization.add_user(declared(params)[:user].merge(admin: true))
                  present organization, with: Entities::V2::Organization
                end
              rescue => ex
                Box.logger.error("[Registration] #{ex.message}")
                error!({message: "Failed to create organization!"}, 400)
              end
            end
          end
        end
      end
    end
  end
end
