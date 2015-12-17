require 'grape-entity'

module Epics
  module Box
    module Entities
      class Subscriber < Grape::Entity
        expose(:account, documentation: { type: "String", desc: "Display name for given bank account" }) do |subscriber|
          subscriber.account.iban
        end
        expose :user_id, documentation: { type: "String", desc: "Associated user id" }
        expose :remote_user_id, as: 'ebics_user', documentation: { type: "String", desc: "EBICS user identifier" }
        expose :signature_class, documentation: { type: "String", desc: "EBICS signature class" }
        expose :state, documentation: { type: "String", desc: "Current subscriber state" }
        expose :submitted_at, documentation: { type: "String", desc: "Date and time when EBICS keys were submitted to bank server" }
        expose :activated_at, documentation: { type: "DateTime", desc: "Date and time when EBICS credentials have been activated" }

        expose(:_links, documentation: { type: "Hash", desc: "Links to resources" }) do |subscriber, options|
          {
            self: Epics::Box.configuration.app_url + "/management/#{subscriber.account.iban}/subscribers/#{subscriber.id}",
            account: Epics::Box.configuration.app_url + "/management/#{subscriber.account.iban}",
            user: Epics::Box.configuration.app_url + "/management/users/#{subscriber.user.try(:id)}",
          }
        end
      end
    end
  end
end
