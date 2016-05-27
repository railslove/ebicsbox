require 'grape'

require_relative './accounts'
require_relative './credit_transfers'
require_relative './service'
require_relative './transactions'


module Box
  module Apis
    module V2
      class Base < Grape::API
        mount Accounts
        mount CreditTransfers
        mount Service
        mount Transactions
      end
    end
  end
end
