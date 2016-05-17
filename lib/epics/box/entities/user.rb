require 'grape-entity'

require_relative './subscriber'

module Epics
  module Box
    module Entities
      class User < Grape::Entity
        expose :id, documentation: { type: "Integer", desc: "Internal user id" }
        expose :name, documentation: { type: "String", desc: "Display name for given bank account" }
        expose :access_token, documentation: { type: "String", desc: "The user's access token" }, if: -> (_, options) { options[:include_token] }
        expose :created_at, documentation: { type: "DateTime", desc: "Date and time when user was created" }
        expose :subscribers, using: Entities::Subscriber, if: { type: "full" }

        expose(:_links, documentation: { type: "Hash", desc: "Links to resources" }) do |user, options|
          {
            self: Epics::Box.configuration.app_url + "/management/users/#{user.id}",
          }
        end
      end
    end
  end
end
