# frozen_string_literal: true

require "grape"
require "grape-swagger"
require "grape-swagger/entity"

module Box
  module Apis
    class OrganizationSetup < Grape::API
      format :json

      before do
        error! :forbidden, 403 unless Box.configuration.ui_initial_setup?
      end

      resource :setup do
        desc "Display init page"
        content_type :html, "text/html"
        get do
          content_type "text/html"
          File.read(File.join("public", "setup", "index.html"))
        end

        desc "Overwrite default organization"
        params do
          requires :organization, type: String, desc: "Name of the organization"
          requires :user_name, type: String, desc: "Name of the user"
        end
        post do
          default_organization = Organization.where(name: "Primary Organization").first
          error! :not_found, 404 unless default_organization
          user = User.where(organization_id: default_organization.id, name: "Primary user", admin: true).first
          error! :not_found, 404 unless user

          default_organization.update(name: params[:organization])
          user.update(name: params[:user_name])

          {
            organization: {name: default_organization.name, webhook_token: default_organization.webhook_token},
            user: {name: user.name, access_token: user.access_token}
          }
        end
      end
    end
  end
end
