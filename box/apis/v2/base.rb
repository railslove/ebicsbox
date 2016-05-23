require 'grape'

require_relative './service'
require_relative './transactions'

module Box
  module Apis
    module V2
      class Base < Grape::API
        mount Service
        mount Transactions
      end
    end
  end
end
