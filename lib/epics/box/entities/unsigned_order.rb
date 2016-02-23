require 'grape-entity'

module Epics
  module Box
    module Entities
      class UnsignedOrder < Grape::Entity
        expose :order_id
        expose :order_type
        expose :created_at do |order|
          order.originator[:timestamp]
        end
        expose :total_orders
        expose :total_amount
        expose :originator, using: Epics::Box::Entities::Originator, as: :requested_by
        expose :signers
        expose :required_signatures
        expose :applied_signatures
        expose :ready_for_signature
        expose :display_file
        expose(:_links, documentation: { type: "Hash", desc: "Links to resources" }) do |order, options|
          {
            self: Box.configuration.app_url + "/unsigned_orders/#{order.order_id}",
          }
        end
      end
    end
  end
end
