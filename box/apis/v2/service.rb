# frozen_string_literal: true

require "grape"

require_relative "./api_endpoint"

module Box
  module Apis
    module V2
      class Service < Grape::API
        include ApiEndpoint

        desc "Service",
          hidden: true

        get do
          {
            version: "v2"
          }
        end
      end
    end
  end
end
