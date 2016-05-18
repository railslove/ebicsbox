require 'active_support/core_ext/string/strip'
require 'ruby-swagger/grape/grape'

require_relative '../../models/event'
require_relative '../../entities/event'

module Box
  module Apis
    module V1
      module Events
        def self.included(api)
          api.resource :events do
            api_desc "List of all events" do
              api_name 'events'
              tags 'Accessible resources'
              detail <<-USAGE.strip_heredoc
                Paginated list of all events which occured on an organization. These are not account
                specific. Each event will trigger a webhook delivery as long as a webhook endpoint
                is specified for an account. To get more data on webhook deliveries, please check an
                events details by following the self source in its _links section.
              USAGE
              response Entities::Event, isArray: true
              headers Content::AUTH_HEADERS
              errors Content::DEFAULT_ERROR_RESPONSES
            end
            params do
              optional :page, type: Integer, desc: "page through the results", default: 1
              optional :per_page, type: Integer, desc: "how many results per page", values: 1..100, default: 10
            end
            api.get do
              record_count = Event.by_organization(current_organization).count
              events = Event.by_organization(current_organization)
                            .paginated(params[:page], params[:per_page])
                            .reverse_order(:triggered_at)
                            .all

              setup_pagination_header(record_count)
              present events, with: Entities::Event
            end

            api_desc "Details for an event" do
              api_name 'event_details'
              tags 'Accessible resources'
              detail <<-USAGE.strip_heredoc
                Get details on every triggered event. In case of a webhook delivery, all attempts
                are listed. For each attempt we store data on its response and errors if any are
                encountered. After 10 attempts, the system will stop to any retries.
              USAGE
              response Entities::Event
              headers Content::AUTH_HEADERS
              errors Content::DEFAULT_ERROR_RESPONSES
            end
            api.get ':id' do
              event = Event.by_organization(current_organization).first!(public_id: params[:id])
              present event, with: Entities::Event, type: 'full'
            end
          end
        end
      end
    end
  end
end
