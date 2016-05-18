require 'grape-entity'

require_relative './subscriber'

module Box
  module Entities
    class RegistrationOrganization < Grape::Entity
      expose :name, documentation: { type: "String", desc: "Display name for given organization" }
      expose :webhook_token, documentation: { type: "String", desc: "Token for validation of webhook signature" }
      expose :user, documentation: { type: "String", desc: "Administrative user which is created along" } do |orga|
        user = orga.users.first
        {
          name: user.name,
          access_token: user.access_token,
        }
      end
    end
  end
end
