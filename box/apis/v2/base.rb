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
require_relative './management/subscribers'
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
        description: <<~USAGE
          A modern API for bank accounts. Fully automatize processing of
          incoming and outgoing money transactions. It enables high-level
          access to some EBCIS features and wrapps them with further
          functinality.

          ## Clarification of terms
          ### EREF
          The most important building block of the EBICS::BOX is the EREF aka
          "End to End ID" or "End to End Reference". It is a universal
          identifier that will be used to recognize transactions throughout
          their whole lifecycle. The maximum length is 35 characters.

          ### Matchmaking
          Every time a new "outgoing" transaction is created (debit or credit)
          the EREF will be stored on the internal watchlist, whenever we're
          seeing these IDs in new transactions you'll get notified via Webhooks.
          The most used use case will be to identify chargebacks or detect that
          the moneywas actullay transfered from your bank account.

          ### Media Types
          All actions require and return JSON formatted data. Timestamps are
          always formatted using ISO 8601. All data is UTF-8 encoded.

            `Content-Type: application/json`

          ### Webhooks
          The account callback url can be defined either through the account
          management UI or directly through the api. When the callback URL is
          set, webhook delivery is enabled.

          If the deliver of a webhooks fails for any reason, it will be
          attempted again up to 20 times, exponentially delaying the execution.

          Following are all supported callbacks with parameters. In
          paranethesis is a short explanation for the non obvious parameters,
          fixed values are written "as strings".

          Account Created:
          ```
          {
            action: "account_created",
            triggered_at (time of event),
            account_id,
            account: {
              id, iban, bic, creditor_identifier, name, url, host, partner,
              callback_url, mode, bankname, organization_id
            }
          }
          ```

          Debit Created:
          ```
          {
            action: "debit_created",
            triggered_at (time of event),
            id (public id),
            account_id,
            transaction: {
              id, eref, type, status, ebics_order_id, ebics_transaction_id
            }
          }
          ```

          Credit Created:
          ```
          {
            action: "credit_created",
            triggered_at (time of event),
            id (public id),
            account_id,
            transaction: {
              id, eref, type, status, ebics_order_id, ebics_transaction_id
            }
          }
          ```

          Statement Created:
          ```
          {
            action: "statement_created",
            triggered_at (time of event),
            account_id,
            statement: {
              id, account (iban), name, bic, iban, type, amount (cents), date,
              remittance_information
            }
          }
          ```

          Subscriber Activated:
          ```
          {
            action: "subscriber_activated",
            triggered_at (time of event),
            subscriber_id,
            account_id,
            user_id,
            subscriber (remote user id),
            signature_class
          }
          ```

          Credit Status Changed:
          ```
          {
            action: "credit_status_changed",
            triggered_at (time of event),
            id,
            account_id,
            transaction: {
              id, eref, type, status, ebics_order_id, ebics_transaction_id
            }
          }
          ```

          Debit Status Changed:
          ```
          {
            action: "debit_status_changed",
            triggered_at (time of event),
            id,
            account_id,
            transaction: {
              id, eref, type, status, ebics_order_id, ebics_transaction_id
            }
          }
          ```


          ### Errors
          Due to its REST nature, the API returns proper http error
          codes. Usually status codes in the 2xx range indicate a successful
          operation, 4xx indicates an error resulting from the provided
          attributes. And errors in the 5xx range indicate a problem in the
          EBICS::BOX. The JSON object returned looks like the following:
          ```
            {
              "message": "Human readable description of the error",
              "errors": {
                "((field))": [ "some error", "another error" ]
              }
            }
          ```

          ### Versioning
          If not specified otherwise, the API will always use the most recent
          version available. In order to use a specific version, clients need
          to request it via header:

          `Accept: application/vnd.ebicsbox-v2+json`

          Please note that we expect applications to be flexible enought to
          accept additional fields without a major version change. Breaking
          changes, like changed behaviour and removal or renaming of fields
          will always result in a version number bump.

          ### Prerequisites
          To use every feature that is offered by the EBICS::BOX you should
          make sure that your bank supports and offers the respective order
          types.

           - Transaction Import: `STA` or `C53`
           - Usage protocols: `HAC`
           - Credits: `CCT`
           - Debits: `CDD`

          Furthermore to process direct debits you'll have to obtain a Creditor
          Identification Number from the
          [Bundesbank](http://www.bundesbank.de/Navigation/DE/Aufgaben/Unbarer_Zahlungsverkehr/SEPA/Glaeubiger_Identifikationsnummer/glaeubiger_identifikationsnummer.html)
          and sign some additional contracts with your bank.
        USAGE
      }
      end
    end
  end
end
