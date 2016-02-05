require 'grape-entity'

require 'epics/box/entities/subscriber'

module Epics
  module Box
    module Entities
      class RegistrationOrganization < Grape::Entity
        expose :name, documentation: { type: "String", desc: "Display name for given organization" }
        expose :management_token, documentation: { type: "String", desc: "Token to access management features" }
        expose :webhook_token, documentation: { type: "String", desc: "Token for validation of webhook signature" }
      end
    end
  end
end
