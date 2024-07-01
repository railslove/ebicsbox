# frozen_string_literal: true

require "grape-entity"

require_relative "../ebics_user"
require_relative "../user"

module Box
  module Entities
    module V2
      class Organization < Grape::Entity
        expose :name, documentation: {type: "String", desc: "Display name for given organization"}
        expose :webhook_token, documentation: {type: "String", desc: "Token for validation of webhook signature"}
        expose :users, documentation: {type: "String", desc: "Administrative user which is created along"}, using: Entities::User
      end
    end
  end
end
