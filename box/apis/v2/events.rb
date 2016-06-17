require 'grape'

require_relative '../../models/event'
require_relative '../../entities/v2/event'

module Box
  module Apis
    module V2
      class Events < Grape::API
        include ApiEndpoint

        resource :events do
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

          get ':id' do
            event = Box::Event.by_organization(current_organization).first!(public_id: params[:id])
            present event, with: Entities::V2::Event, type: 'full'
          end
        end
      end
    end
  end
end
