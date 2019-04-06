require 'grape'

require_relative './api_endpoint'
require_relative '../../entities/v2/event'

module Box
  module Apis
    module V2
      class Webhooks < Grape::API
        include ApiEndpoint

        resource :webhooks do
          desc 'reset'
          post 'reset' do
            events = Event.where(Sequel.~(webhook_status: 'success'))

            events.each do |event|
              event
                .set(webhook_status: 'pending', webhook_retries: 0)
                .save
            end
          end
        end
      end
    end
  end
end
