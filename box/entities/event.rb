# frozen_string_literal: true

require "grape-entity"

require_relative "webhook_delivery"

module Box
  module Entities
    class Event < Grape::Entity
      expose :public_id, as: "id"
      expose(:account, documentation: {type: "String", desc: "Display name for given bank account"}) do |event|
        event.account.try(:iban)
      end
      expose :type
      expose(:payload) do |event|
        event.payload.delete "public_id"
        event.payload
      end
      expose :triggered_at
      expose :signature
      expose :webhook_status
      expose :webhook_retries

      expose :webhook_deliveries, using: Entities::WebhookDelivery, if: {type: "full"}

      expose(:_links, documentation: {type: "Hash", desc: "Links to resources"}) do |event, _options|
        {
          self: Box.configuration.app_url + "/events/#{event.public_id}",
          account: Box.configuration.app_url + "/accounts/#{event.account.try(:iban)}"
        }
      end
    end
  end
end
