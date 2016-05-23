require 'grape'

require_relative './service'

module Box
  module Apis
    module V2
      class Base < Grape::API
        mount Service
      end
    end
  end
end
