require_relative './content'
require_relative './management'
require_relative './registration'
require_relative './service'

module Box
  module Apis
    module V1
      class Base < Grape::API
        version 'v1', using: :header, vendor: 'ebicsbox'
        format :json

        mount Service
        mount Management
        mount Content
        mount Registration
      end
    end
  end
end
