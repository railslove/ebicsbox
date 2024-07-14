# frozen_string_literal: true

require "grape"
require "grape-swagger"
require "grape-swagger/entity"

module Box
  module Apis
    class Healthcheck < Grape::API
      version "v2", using: :header, vendor: "ebicsbox"
      format :json

      resource :health do
        desc "Health check endpoint",
          success: [{code: 200, message: "service ok"}],
          failure: [{code: 500, message: "Internal server error"}]
        get do
          {status: "ok"}
        end
      end
    end
  end
end
