# frozen_string_literal: true

require "grape-entity"

require_relative "./ebics_user"

module Box
  module Entities
    class User < Grape::Entity
      expose :id, documentation: {type: "Integer", desc: "Internal user id"}
      expose :name, documentation: {type: "String", desc: "Display name for given bank account"}
      expose :access_token, documentation: {type: "String", desc: "The user's access token"}, if: :include_token
      expose :created_at, documentation: {type: "DateTime", desc: "Date and time when user was created"}
      expose :admin, documentation: {type: "Boolean", desc: "Display admin state"}, if: :include_token
      expose :ebics_users, using: Entities::EbicsUser, if: {type: "full"}

      expose(:_links, documentation: {type: "Hash", desc: "Links to resources"}) do |user, _options|
        {
          self: Box.configuration.app_url + "/management/users/#{user.id}"
        }
      end
    end
  end
end
