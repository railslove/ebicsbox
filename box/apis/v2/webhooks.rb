require 'grape'

require_relative './api_endpoint'
require_relative '../../models/event'
require_relative '../../entities/v2/event'

module Box
  module Apis
    module V2
      class Webhooks < Grape::API
        include ApiEndpoint

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
              receive webhooks which have not been received yet dues to e.g.
              an outage
            USAGE
          post 'reset' do
            events = Box::Event.where(Sequel.~(webhook_status: 'success')).all

            events.each do |event|
              event
                .set(webhook_status: 'pending', webhook_retries: 0)
                .save

              Queue.trigger_webhook(event_id: event.id)
            end

            present [], with: Entities::V2::Event
          end
        end
      end
    end
  end
end
