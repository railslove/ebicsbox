# frozen_string_literal: true

require "active_support/concern"

require_relative "../../helpers/pagination"

module Box
  module Apis
    module V2
      module ApiEndpoint
        class Message < Grape::Entity
          expose(:message)
        end

        DEFAULT_ERROR_RESPONSES = [
          [400, "Invalid request", Message],
          [401, "Not authorized to access this resource", Message],
          [404, "Resource not found", Message],
          [412, "EBICS account credentials not yet activated", Message],
          [500, "Internal Server error"]
        ].freeze

        AUTH_HEADERS = {
          "Authorization" => {description: "OAuth 2 Bearer token", required: true, default: "Bearer "}
        }.freeze

        extend ActiveSupport::Concern

        included do
          version "v2", using: :header, vendor: "ebicsbox"
          format :json
          helpers Helpers::Pagination
          helpers Helpers::ErrorHandler

          rescue_from :all do |exception|
            log_error(exception)
            error!({error: "Internal server error"}, 500, {"Content-Type" => "application/json"})
          end

          helpers do
            def current_user
              env["box.user"]
            end

            def current_organization
              env["box.organization"]
            end

            def logger
              Box.logger
            end
          end

          before do
            error!({message: "Unauthorized access. Please provide a valid access token!"}, 401) if current_user.nil?
          end

          rescue_from Grape::Exceptions::ValidationErrors do |e|
            error!({
              message: "Validation of your request's payload failed!",
              errors: e.errors.map { |k, v| [k.first, v] }.to_h
            }, 400)
          end
        end
      end
    end
  end
end
