# GET: /unsigned_orders
#   [
#     {
#       "order_id": "123",
#       "order_type": "credit",
#       "created_at": "2015-10-26 10:00:00",
#       "total_orders": 1,
#       "total_amount": 123.45,
#       "requested_by": {
#         "name": "Peter Müller",
#         signature_class: "T"
#       },
#       "signed_by": [
#         { "name": "Max Mustermann", type: "A" },
#         { "name": "Peter Müller", type: "B" }
#       ]
#     }
#   ]

module Epics
  module Box
    module DistributedSignature
      def self.included(api)
        api.resource 'unsigned_orders' do
          api.get do
            unsigned_orders = current_user.unsigned_orders
            present unsigned_orders, with: Entities::UnsignedOrder
          end

          api.get ':order_id' do
            order = current_user.unsigned_orders.select{ |o| o.order_id == params['order_id'] }.first
            present order, with: Entities::UnsignedOrder
          end

          api.put ':order_id' do
            new_order_id = current_user.sign_order(params['order_id'])
            { order_id: new_order_id }
          end

          api.delete ':order_id' do
            new_order_id = current_user.cancel_order(params['order_id'])
            { order_id: new_order_id }
          end
        end
      end
    end
  end
end
