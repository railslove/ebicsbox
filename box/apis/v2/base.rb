require 'grape'

require_relative './service'

module Box
  module Apis
    module V2
      class Base < Grape::API
        version 'v2', using: :header, vendor: 'ebicsbox'
        format :json

        mount Service
      end
    end
  end
end
