# frozen_string_literal: true

require "grape"

require_relative "./api_endpoint"
require_relative "../../models/event"
require_relative "../../entities/v2/event"

module Box
  module Apis
    module V2
      class Events < Grape::API
        include ApiEndpoint

        resource :events do
          desc "List of all events",
            is_array: true,
            headers: AUTH_HEADERS,
            success: Entities::V2::Event,
            failure: DEFAULT_ERROR_RESPONSES,
            produces: ["application/vnd.ebicsbox-v2+json"],
            detail: <<-USAGE.strip_heredoc
              Paginated list of all events which occured on an organization. These are not account
              specific. Each event will trigger a webhook delivery as long as a webhook endpoint
              is specified for an account. To get more data on webhook deliveries, please check an
              events details by following the self source in its _links section.
            USAGE

          params do
            optional :page, type: Integer, desc: "page through the results", default: 1
            optional :per_page, type: Integer, desc: "how many results per page", values: 1..100, default: 10
          end

          get do
            record_count = Box::Event.by_organization(current_organization).count
            events = Box::Event.by_organization(current_organization)
              .paginated(params[:page], params[:per_page])
              .reverse_order(:triggered_at)
              .all

            setup_pagination_header(record_count)
            present events, with: Entities::V2::Event
          end

          desc "Details for an event",
            name: "event_details",
            headers: AUTH_HEADERS,
            success: Entities::V2::Event,
            failure: DEFAULT_ERROR_RESPONSES,
            produces: ["application/vnd.ebicsbox-v2+json"],
            detail: <<-USAGE.strip_heredoc
              Get details on every triggered event. In case of a webhook delivery, all attempts
              are listed. For each attempt we store data on its response and errors if any are
              encountered. After 20 attempts, the system will stop to any retries.
            USAGE

          params do
            requires :id, type: String
          end
          get ":id" do
            event = Box::Event.by_organization(current_organization).first!(public_id: params[:id])
            present event, with: Entities::V2::Event, type: "full"
          end
        end
      end
    end
  end
end
