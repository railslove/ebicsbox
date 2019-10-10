# frozen_string_literal: true

require 'grape'

require_relative '../api_endpoint'
require_relative '../../../models/event'
require_relative '../../../entities/v2/event'

module Box
  module Apis
    module V2
      class Management < Grape::API
        include ApiEndpoint

        namespace :management do
          resource :webhooks do
            desc 'Reset the retry count to 0 for pending and failed events',
                 is_array: true,
                 headers: AUTH_HEADERS,
                 success: Entities::V2::Event,
                 failure: DEFAULT_ERROR_RESPONSES,
                 produces: ['application/vnd.ebicsbox-v2+json'],
                 detail: <<~USAGE
                   The webhooks will only be retried 20 times, after that a
                   consuming application can reset the webhook status here to
                   receive webhooks which have not been received yet dues to
                   e.g. an outage
                 USAGE
            post 'reset' do
              events = Box::Event
                       .by_organization(current_organization)
                       .exclude(webhook_status: 'success')
                       .all

              events.each(&:reset_webhook_delivery)

              present events, with: Entities::V2::Event
            end
          end
        end
      end
    end
  end
end
