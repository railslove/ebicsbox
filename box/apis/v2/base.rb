require 'grape'
require 'grape-swagger'
require 'grape-swagger/entity'

require_relative './accounts'
require_relative './credit_transfers'
require_relative './direct_debits'
require_relative './service'
require_relative './events'
require_relative './webhooks'
require_relative './transactions'
require_relative './management/accounts'
require_relative './management/ebics_users'
require_relative './management/users'


module Box
  module Apis
    module V2
      class Base < Grape::API
        version 'v2', using: :header, vendor: 'ebicsbox'

        mount Accounts
        mount CreditTransfers
        mount DirectDebits
        mount Service
        mount Transactions
        mount Events
        mount Management
        mount Webhooks

        add_swagger_documentation \
          doc_version: 'v2',
          mount_path: '/swagger_doc',
          info: {
        title: "EBICS::Box",
        contact_name: "Railslove GmbH",
        contact_email: "ebics-box@railslove.com",
        contact_url: "https://www.ebicsbox.com/",
        description: File.read('box/apis/v2/documentation.yml')
      }
      end
    end
  end
end
