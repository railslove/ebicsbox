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
            current_user.unsigned_orders
          end
        end
      end
    end
  end
end
