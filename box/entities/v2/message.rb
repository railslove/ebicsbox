require 'grape-entity'
require_relative './transaction'

module Box
  module Entities
    module V2
      class Message < Grape::Entity
        expose(:message)
      end
    end
  end
end
