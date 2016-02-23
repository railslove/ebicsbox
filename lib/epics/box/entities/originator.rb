require 'grape-entity'

module Epics
  module Box
    module Entities
      class Originator < Grape::Entity
        expose :name
        expose :partner_id
        expose :user_id
      end
    end
  end
end
