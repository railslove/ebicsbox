module Epics
  module Http
    class Server < Grape::API

      helpers do
        def queue
          @queue ||= Epics::Http::QUEUE.new
        end
        def redis
          @redis  ||= Redis.new
        end
      end

      params do
        requires :document,  type: String, desc: "document to submit"
        requires :callback,  type: String, desc: "where to push the callback"
        optional :order_type, type: String, default: "cdd", desc: "Which order type should be used?", values: ["cdd", "cd1"]
      end
      desc "Return a public timeline."
      post :debits do
        queue.publish params[:order_type], params.slice(:document, :callback)

        {debit: 'ok'}
      end

      params do
        requires :callback,  type: String, desc: "where to push the callback"
        requires :document,  type: String, desc: "document to submit"
      end
      desc "Return a public timeline."
      post :credits do
        queue.publish params[:order_type], params.slice(:document, :callback)

        {credit: 'ok'}
      end
    end
  end
end
