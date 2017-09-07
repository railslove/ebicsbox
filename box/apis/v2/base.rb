require 'grape'

require_relative './accounts'
require_relative './credit_transfers'
require_relative './direct_debits'
require_relative './service'
require_relative './events'
require_relative './transactions'


module Box
  module Apis
    module V2
      class Base < Grape::API
        mount Accounts
        mount CreditTransfers
        mount DirectDebits
        mount Service
        mount Transactions
        mount Events
      end
    end
  end
end
