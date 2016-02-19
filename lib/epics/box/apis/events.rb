require_relative '../models/event'
require_relative '../entities/event'

module Epics
  module Box
    module Apis
      module Events
        def self.included(api)
          api.resource :events do
            api.get do
              events = Event.by_organization(current_organization).all
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
