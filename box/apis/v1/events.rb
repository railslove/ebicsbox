require 'active_support/core_ext/string/strip'

require_relative '../../models/event'
require_relative '../../entities/event'

module Box
  module Apis
    module V1
      module Events
        def self.included(api)
          api.resource :events do
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
